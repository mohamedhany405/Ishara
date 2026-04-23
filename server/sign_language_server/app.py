"""
Ishara Sign Language Detection Server
======================================
Real-time Arabic Sign Language detection via WebSocket.

The Flutter app streams base64-encoded camera frames to this server.
MediaPipe Holistic extracts 1692 keypoints per frame, then the LSTM
model (V6) predicts the sign from a 30-frame sequence.

Usage:
    pip install -r requirements.txt
    python app.py                          # default port 5001
    python app.py --port 8000              # custom port
    python app.py --model path/to/model    # custom model path
"""

import argparse
import base64
import json
import time
from collections import deque
from pathlib import Path

import cv2
import eventlet
eventlet.monkey_patch()

import numpy as np
import mediapipe as mp
from flask import Flask, request
from flask_cors import CORS
from flask_socketio import SocketIO, emit

# ── MediaPipe Holistic setup ─────────────────────────────────────────────────

mp_holistic = mp.solutions.holistic
mp_drawing = mp.solutions.drawing_utils
mp_drawing_styles = mp.solutions.drawing_styles


def create_holistic():
    return mp_holistic.Holistic(
        min_detection_confidence=0.7,
        min_tracking_confidence=0.7,
        model_complexity=1,
    )


def extract_keypoints(results) -> np.ndarray:
    """Extract the 1692-dim keypoint vector matching V6 training pipeline."""
    # Pose: 33 landmarks × 4 (x, y, z, visibility) = 132
    if results.pose_landmarks:
        pose = np.array([
            [lm.x, lm.y, lm.z, lm.visibility]
            for lm in results.pose_landmarks.landmark
        ]).flatten()
    else:
        pose = np.zeros(33 * 4)

    # Face: 468 landmarks × 3 (x, y, z) = 1404
    if results.face_landmarks:
        face = np.array([
            [lm.x, lm.y, lm.z]
            for lm in results.face_landmarks.landmark
        ]).flatten()
    else:
        face = np.zeros(468 * 3)

    # Left hand: 21 landmarks × 3 (x, y, z) = 63
    if results.left_hand_landmarks:
        lh = np.array([
            [lm.x, lm.y, lm.z]
            for lm in results.left_hand_landmarks.landmark
        ]).flatten()
    else:
        lh = np.zeros(21 * 3)

    # Right hand: 21 landmarks × 3 (x, y, z) = 63
    if results.right_hand_landmarks:
        rh = np.array([
            [lm.x, lm.y, lm.z]
            for lm in results.right_hand_landmarks.landmark
        ]).flatten()
    else:
        rh = np.zeros(21 * 3)

    return np.concatenate([pose, face, lh, rh])  # Total: 1692


# ── Temporal smoother (matches V6 Python inference) ──────────────────────────

class TemporalSmoother:
    def __init__(self, window_size=10, confidence_threshold=0.80, cooldown_seconds=1.0):
        self.window_size = window_size
        self.confidence_threshold = confidence_threshold
        self.cooldown_seconds = cooldown_seconds
        self.predictions = deque(maxlen=window_size)
        self.last_prediction_time = 0
        self.last_predicted_class = None

    def update(self, probs: np.ndarray):
        self.predictions.append(probs)
        if len(self.predictions) < 3:
            return None, None

        avg_probs = np.mean(list(self.predictions), axis=0)
        pred_idx = int(np.argmax(avg_probs))
        conf = float(avg_probs[pred_idx])

        if conf < self.confidence_threshold:
            return None, None

        now = time.time()
        if (now - self.last_prediction_time) < self.cooldown_seconds:
            if pred_idx == self.last_predicted_class:
                return None, None

        self.last_prediction_time = now
        self.last_predicted_class = pred_idx
        return pred_idx, conf

    def reset(self):
        self.predictions.clear()
        self.last_prediction_time = 0
        self.last_predicted_class = None


# ── Flask + SocketIO app ─────────────────────────────────────────────────────

app = Flask(__name__)
CORS(app)
socketio = SocketIO(app, cors_allowed_origins="*", async_mode='eventlet')

# Global state per connection
sessions = {}
LOW_LIGHT_THRESHOLD = 45.0
MAX_FRAME_WIDTH = 640


def load_model_and_labels(model_path: str, label_map_path: str):
    """Load TFLite model and label map."""
    import tensorflow as tf

    interpreter = tf.lite.Interpreter(model_path=model_path)
    interpreter.allocate_tensors()

    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()

    with open(label_map_path, 'r', encoding='utf-8') as f:
        label_map = json.load(f)

    index_to_label = [''] * len(label_map)
    for action, idx in label_map.items():
        index_to_label[idx] = action

    return interpreter, input_details, output_details, index_to_label


# Will be set in main()
interpreter = None
input_details = None
output_details = None
index_to_label = []
SEQUENCE_LENGTH = 30


def run_inference(sequence: np.ndarray) -> np.ndarray:
    """Run TFLite inference on a sequence of keypoints."""
    input_data = np.expand_dims(sequence, axis=0).astype(np.float32)
    interpreter.set_tensor(input_details[0]['index'], input_data)
    interpreter.invoke()
    output_data = interpreter.get_tensor(output_details[0]['index'])
    return output_data[0]  # softmax probabilities


def decode_frame_payload(data: dict):
    """
    Decode frame payload from Flutter.

    Supported payloads:
      - {'image': <base64-jpeg>}
      - {'luma': <base64-grayscale>, 'width': int, 'height': int}

    Returns:
      (frame_bgr, gray_uint8)
    """
    if 'luma' in data:
        width = int(data.get('width', 0))
        height = int(data.get('height', 0))
        if width <= 0 or height <= 0:
            raise ValueError('Invalid luma frame dimensions.')

        luma_bytes = base64.b64decode(data['luma'])
        expected = width * height
        if len(luma_bytes) != expected:
            raise ValueError(
                f'Invalid luma payload size: expected {expected}, got {len(luma_bytes)}.'
            )

        gray = np.frombuffer(luma_bytes, dtype=np.uint8).reshape((height, width))
        frame = cv2.cvtColor(gray, cv2.COLOR_GRAY2BGR)
        return frame, gray

    if 'image' in data:
        img_bytes = base64.b64decode(data['image'])
        nparr = np.frombuffer(img_bytes, np.uint8)
        frame = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        if frame is None:
            raise ValueError('Invalid JPEG image payload.')
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        return frame, gray

    raise ValueError("Frame payload must include either 'image' or 'luma'.")


@app.route('/')
def index():
    return {'status': 'ok', 'service': 'Ishara Sign Language Server'}


@app.route('/health')
def health():
    return {
        'status': 'ok',
        'model_loaded': interpreter is not None,
        'labels': index_to_label,
        'sequence_length': SEQUENCE_LENGTH,
    }


@socketio.on('connect')
def on_connect():
    sid = request.sid
    sessions[sid] = {
        'holistic': create_holistic(),
        'sequence': [],
        'smoother': TemporalSmoother(
            window_size=10,
            confidence_threshold=0.80,
            cooldown_seconds=1.0,
        ),
        'sentence': [],
    }
    print(f"✅ Client connected: {sid}")
    emit('connected', {'labels': index_to_label, 'sequence_length': SEQUENCE_LENGTH})


@socketio.on('disconnect')
def on_disconnect():
    sid = request.sid
    if sid in sessions:
        sessions[sid]['holistic'].close()
        del sessions[sid]
    print(f"❌ Client disconnected: {sid}")


@socketio.on('frame')
def on_frame(data):
    """
    Receive a base64-encoded JPEG frame from the Flutter app.
    Extract keypoints, run LSTM if sequence is full, return prediction.
    """
    sid = request.sid
    if sid not in sessions:
        return

    session = sessions[sid]
    holistic = session['holistic']
    sequence = session['sequence']
    smoother = session['smoother']

    try:
        if not isinstance(data, dict):
            emit('error', {'message': 'Invalid frame payload'})
            return

        frame, gray = decode_frame_payload(data)

        if frame.shape[1] > MAX_FRAME_WIDTH:
            scale = MAX_FRAME_WIDTH / frame.shape[1]
            new_w = int(frame.shape[1] * scale)
            new_h = int(frame.shape[0] * scale)
            frame = cv2.resize(frame, (new_w, new_h), interpolation=cv2.INTER_AREA)
            gray = cv2.resize(gray, (new_w, new_h), interpolation=cv2.INTER_AREA)

        ambient_brightness = float(np.mean(gray))
        low_light = ambient_brightness < LOW_LIGHT_THRESHOLD

        # Run MediaPipe Holistic
        rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        rgb.flags.writeable = False
        results = holistic.process(rgb)
        rgb.flags.writeable = True

        # Check hand detection
        hands_detected = bool(
            results.left_hand_landmarks or results.right_hand_landmarks
        )

        # Extract keypoints
        keypoints = extract_keypoints(results)
        sequence.append(keypoints)

        # Keep only last SEQUENCE_LENGTH frames
        if len(sequence) > SEQUENCE_LENGTH:
            session['sequence'] = sequence[-SEQUENCE_LENGTH:]
            sequence = session['sequence']

        # Status update
        status = {
            'hands_detected': hands_detected,
            'face_detected': results.face_landmarks is not None,
            'frames_collected': len(sequence),
            'frames_needed': SEQUENCE_LENGTH,
            'low_light': low_light,
            'ambient_brightness': round(ambient_brightness, 1),
        }

        # Run prediction if we have enough frames and hands are detected
        if len(sequence) == SEQUENCE_LENGTH and hands_detected:
            seq_array = np.asarray(sequence, dtype=np.float32)
            probs = run_inference(seq_array)

            pred_idx, conf = smoother.update(probs)

            if pred_idx is not None and conf is not None:
                word = index_to_label[pred_idx]
                sentence = session['sentence']
                if not sentence or word != sentence[-1]:
                    sentence.append(word)
                    if len(sentence) > 10:
                        session['sentence'] = sentence[-10:]

                emit('prediction', {
                    'word': word,
                    'confidence': round(conf, 4),
                    'sentence': ' '.join(session['sentence']),
                    'all_probs': {
                        label: round(float(p), 4)
                        for label, p in zip(index_to_label, probs)
                    },
                    **status,
                })
                return

        # No prediction yet, just status
        emit('status', status)

    except Exception as e:
        print(f"Error processing frame: {e}")
        emit('error', {'message': str(e)})


@socketio.on('reset')
def on_reset():
    """Reset the sequence and sentence for this client."""
    sid = request.sid
    if sid in sessions:
        sessions[sid]['sequence'].clear()
        sessions[sid]['sentence'].clear()
        sessions[sid]['smoother'].reset()
    emit('reset_ack', {'message': 'Session reset'})


def main():
    global interpreter, input_details, output_details, index_to_label, SEQUENCE_LENGTH

    parser = argparse.ArgumentParser(description='Ishara Sign Language Server')
    parser.add_argument('--port', type=int, default=5001, help='Port to run on')
    parser.add_argument('--host', type=str, default='0.0.0.0', help='Host to bind')
    parser.add_argument(
        '--model',
        type=str,
        default=None,
        help='Path to asl_v6.tflite model file',
    )
    parser.add_argument(
        '--labels',
        type=str,
        default=None,
        help='Path to label_map_v6.json',
    )
    args = parser.parse_args()

    # Find model files
    script_dir = Path(__file__).resolve().parent
    assets_dir = script_dir.parent / 'assets' / 'models'

    model_path = args.model or str(assets_dir / 'asl_v6.tflite')
    labels_path = args.labels or str(assets_dir / 'label_map_v6.json')

    # Also check in V67 directory
    if not Path(model_path).exists():
        alt_model = script_dir.parent.parent.parent / 'V67' / 'v66' / 'Ishara' / 'assets' / 'models' / 'asl_v6.tflite'
        if alt_model.exists():
            model_path = str(alt_model)

    if not Path(labels_path).exists():
        alt_labels = script_dir.parent.parent.parent / 'V67' / 'v66' / 'Ishara' / 'assets' / 'models' / 'label_map_v6.json'
        if alt_labels.exists():
            labels_path = str(alt_labels)

    # Load the manifest to get sequence length
    manifest_path = Path(model_path).parent / 'manifest.json'
    if manifest_path.exists():
        with open(manifest_path, 'r') as f:
            manifest = json.load(f)
            SEQUENCE_LENGTH = manifest.get('sequence_length', 30)

    print("=" * 60)
    print("🤟 ISHARA SIGN LANGUAGE SERVER")
    print("=" * 60)
    print(f"  Model:    {model_path}")
    print(f"  Labels:   {labels_path}")
    print(f"  Seq len:  {SEQUENCE_LENGTH}")
    print(f"  Host:     {args.host}:{args.port}")
    print("=" * 60)

    if not Path(model_path).exists():
        print(f"❌ Model not found at {model_path}")
        print("   Please provide --model path/to/asl_v6.tflite")
        return

    if not Path(labels_path).exists():
        print(f"❌ Label map not found at {labels_path}")
        return

    interpreter, input_details, output_details, index_to_label = load_model_and_labels(
        model_path, labels_path
    )
    print(f"✅ Model loaded. Labels: {index_to_label}")
    print(f"🚀 Server starting on http://{args.host}:{args.port}")

    socketio.run(app, host=args.host, port=args.port, debug=False)


if __name__ == '__main__':
    main()
