import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show Size;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'tflite_flutter_web_stub.dart'
    if (dart.library.io) 'package:tflite_flutter/tflite_flutter.dart';

/// Result emitted when a sign has been accepted by the temporal smoother.
class SignDetectionResult {
  final String word;
  final double confidence;
  final String sentence;
  final Map<String, double> allProbs;
  final bool handsDetected;
  final bool faceDetected;
  final bool lowLight;
  final double ambientBrightness;
  final int framesCollected;
  final int framesNeeded;

  const SignDetectionResult({
    required this.word,
    required this.confidence,
    required this.sentence,
    required this.allProbs,
    required this.handsDetected,
    required this.faceDetected,
    required this.lowLight,
    required this.ambientBrightness,
    required this.framesCollected,
    required this.framesNeeded,
  });
}

/// Status emitted while collecting frames or when no stable prediction exists yet.
class SignDetectionStatus {
  final bool handsDetected;
  final bool faceDetected;
  final bool lowLight;
  final double ambientBrightness;
  final int framesCollected;
  final int framesNeeded;

  const SignDetectionStatus({
    required this.handsDetected,
    required this.faceDetected,
    required this.lowLight,
    required this.ambientBrightness,
    required this.framesCollected,
    required this.framesNeeded,
  });
}

/// Streaming diagnostics for the on-device pipeline.
class SignStreamMetrics {
  final double outgoingFps;
  final int sentFrames;
  final int droppedFrames;

  const SignStreamMetrics({
    required this.outgoingFps,
    required this.sentFrames,
    required this.droppedFrames,
  });
}

class _SmoothedPrediction {
  final int index;
  final double confidence;

  const _SmoothedPrediction({required this.index, required this.confidence});
}

class _TemporalSmoother {
  _TemporalSmoother({
    required this.windowSize,
    required this.confidenceThreshold,
    required this.marginThreshold,
    required this.minStableFrames,
    required this.cooldown,
  });

  final int windowSize;
  final double confidenceThreshold;
  final double marginThreshold;
  final int minStableFrames;
  final Duration cooldown;

  final List<List<double>> _history = <List<double>>[];
  DateTime _lastAcceptedAt = DateTime.fromMillisecondsSinceEpoch(0);
  int? _lastAcceptedIndex;
  int? _candidateIndex;
  int _stableCount = 0;

  _SmoothedPrediction? update(List<double> probs) {
    _history.add(probs);
    if (_history.length > windowSize) {
      _history.removeAt(0);
    }

    if (_history.length < 3) {
      return null;
    }

    final averaged = List<double>.filled(probs.length, 0.0);
    for (final frame in _history) {
      for (var i = 0; i < frame.length; i++) {
        averaged[i] += frame[i];
      }
    }
    for (var i = 0; i < averaged.length; i++) {
      averaged[i] /= _history.length;
    }

    var topIdx = 0;
    var topVal = averaged[0];
    var secondVal = -double.infinity;
    for (var i = 1; i < averaged.length; i++) {
      final value = averaged[i];
      if (value > topVal) {
        secondVal = topVal;
        topVal = value;
        topIdx = i;
      } else if (value > secondVal) {
        secondVal = value;
      }
    }

    final confidenceOk = topVal >= confidenceThreshold;
    final marginOk = (topVal - secondVal) >= marginThreshold;
    if (!confidenceOk || !marginOk) {
      _candidateIndex = null;
      _stableCount = 0;
      return null;
    }

    if (_candidateIndex == topIdx) {
      _stableCount += 1;
    } else {
      _candidateIndex = topIdx;
      _stableCount = 1;
    }

    if (_stableCount < minStableFrames) {
      return null;
    }

    final now = DateTime.now();
    final inCooldown = now.difference(_lastAcceptedAt) < cooldown;
    if (inCooldown && _lastAcceptedIndex == topIdx) {
      return null;
    }

    _lastAcceptedAt = now;
    _lastAcceptedIndex = topIdx;
    _stableCount = 0;
    _candidateIndex = null;
    return _SmoothedPrediction(index: topIdx, confidence: topVal);
  }

  void reset() {
    _history.clear();
    _lastAcceptedAt = DateTime.fromMillisecondsSinceEpoch(0);
    _lastAcceptedIndex = null;
    _candidateIndex = null;
    _stableCount = 0;
  }
}

/// Fully local sign language pipeline: camera -> pose landmarks -> TFLite inference.
class SignLanguageService {
  static const String _manifestAssetPath = 'assets/models/manifest.json';
  static const String _defaultModelFile = 'asl_v6.tflite';
  static const String _defaultLabelFile = 'label_map_v6.json';

  static const int _defaultSequenceLength = 30;
  static const int _defaultFeatureSize = 1692;
  static const int _minFrameSkip = 1;
  static const int _maxFrameSkip = 4;
  static const Duration _minProcessInterval = Duration(milliseconds: 78);
  static const double _lowLightThreshold = 45.0;

  static const List<PoseLandmarkType> _poseOrder = <PoseLandmarkType>[
    PoseLandmarkType.nose,
    PoseLandmarkType.leftEyeInner,
    PoseLandmarkType.leftEye,
    PoseLandmarkType.leftEyeOuter,
    PoseLandmarkType.rightEyeInner,
    PoseLandmarkType.rightEye,
    PoseLandmarkType.rightEyeOuter,
    PoseLandmarkType.leftEar,
    PoseLandmarkType.rightEar,
    PoseLandmarkType.leftMouth,
    PoseLandmarkType.rightMouth,
    PoseLandmarkType.leftShoulder,
    PoseLandmarkType.rightShoulder,
    PoseLandmarkType.leftElbow,
    PoseLandmarkType.rightElbow,
    PoseLandmarkType.leftWrist,
    PoseLandmarkType.rightWrist,
    PoseLandmarkType.leftPinky,
    PoseLandmarkType.rightPinky,
    PoseLandmarkType.leftIndex,
    PoseLandmarkType.rightIndex,
    PoseLandmarkType.leftThumb,
    PoseLandmarkType.rightThumb,
    PoseLandmarkType.leftHip,
    PoseLandmarkType.rightHip,
    PoseLandmarkType.leftKnee,
    PoseLandmarkType.rightKnee,
    PoseLandmarkType.leftAnkle,
    PoseLandmarkType.rightAnkle,
    PoseLandmarkType.leftHeel,
    PoseLandmarkType.rightHeel,
    PoseLandmarkType.leftFootIndex,
    PoseLandmarkType.rightFootIndex,
  ];

  Interpreter? _interpreter;
  PoseDetector? _poseDetector;
  CameraController? _cameraController;

  bool _isModelReady = false;
  bool _isStreaming = false;
  bool _isProcessingFrame = false;

  int _sequenceLength = _defaultSequenceLength;
  int _featureSize = _defaultFeatureSize;
  List<String> _labels = <String>[];

  List<List<double>> _featureRing = <List<double>>[];
  List<List<double>> _orderedSequence = <List<double>>[];
  List<List<List<double>>> _modelInput = <List<List<double>>>[];
  List<List<double>> _modelOutput = <List<double>>[];
  int _sequenceWriteIndex = 0;
  int _sequenceCount = 0;

  final List<String> _sentence = <String>[];
  final _TemporalSmoother _smoother = _TemporalSmoother(
    windowSize: 9,
    confidenceThreshold: 0.78,
    marginThreshold: 0.13,
    minStableFrames: 2,
    cooldown: const Duration(milliseconds: 850),
  );

  int _incomingFrameCount = 0;
  int _dynamicFrameSkip = _minFrameSkip;
  DateTime _lastProcessedAt = DateTime.fromMillisecondsSinceEpoch(0);

  int _processedFramesTotal = 0;
  int _droppedFramesTotal = 0;
  int _metricsWindowProcessed = 0;
  DateTime _metricsWindowStart = DateTime.now();
  int _preconditionErrorBurst = 0;
  DateTime _lastPoseDetectorResetAt = DateTime.fromMillisecondsSinceEpoch(0);

  void Function(SignDetectionResult)? onPrediction;
  void Function(SignDetectionStatus)? onStatus;
  void Function(SignStreamMetrics)? onMetrics;
  void Function(String)? onError;
  void Function(bool)? onConnectionChanged;
  void Function(List<String>)? onLabelsReceived;

  bool get isConnected => _isModelReady;
  bool get isModelReady => _isModelReady;
  bool get isStreaming => _isStreaming;
  CameraController? get cameraController => _cameraController;

  Future<bool> loadModel() async {
    if (_isModelReady) {
      return true;
    }

    try {
      final manifest = await _loadManifest();
      final manifestSequenceLength =
          (manifest['sequence_length'] as num?)?.toInt() ??
          _defaultSequenceLength;
      _sequenceLength =
          manifestSequenceLength > 0
              ? manifestSequenceLength
              : _defaultSequenceLength;

      final manifestFeatureSize =
          (manifest['num_keypoints'] as num?)?.toInt() ?? _defaultFeatureSize;
      _featureSize =
          manifestFeatureSize > 0 ? manifestFeatureSize : _defaultFeatureSize;

      final modelFile =
          (manifest['model_file'] as String?)?.trim().isNotEmpty == true
              ? manifest['model_file'] as String
              : _defaultModelFile;
      final labelFile =
          (manifest['label_map_file'] as String?)?.trim().isNotEmpty == true
              ? manifest['label_map_file'] as String
              : _defaultLabelFile;

      final options = InterpreterOptions()..threads = 2;
      _interpreter = await Interpreter.fromAsset(
        'assets/models/$modelFile',
        options: options,
      );

      final inputShape = _readInputTensorShape();
      if (inputShape != null && inputShape.length >= 3) {
        final inferredSequence = inputShape[inputShape.length - 2];
        final inferredFeatureSize = inputShape.last;
        if (inferredSequence > 0) {
          _sequenceLength = inferredSequence;
        }
        if (inferredFeatureSize > 0) {
          _featureSize = inferredFeatureSize;
        }
      }

      final labelRaw = await rootBundle.loadString('assets/models/$labelFile');
      _labels = _parseLabels(labelRaw);

      if (_labels.isEmpty && manifest['labels'] is List) {
        _labels =
            (manifest['labels'] as List)
                .map((e) => e.toString())
                .where((e) => e.trim().isNotEmpty)
                .toList();
      }

      final outputClasses = _readOutputClassCount();
      if (outputClasses > 0) {
        _labels = _normalizeLabels(_labels, outputClasses);
      }
      _initializeBuffers(math.max(outputClasses, _labels.length));

      _poseDetector = PoseDetector(
        options: PoseDetectorOptions(mode: PoseDetectionMode.stream),
      );

      _isModelReady = true;
      onConnectionChanged?.call(true);
      onLabelsReceived?.call(List<String>.unmodifiable(_labels));
      return true;
    } catch (e) {
      _isModelReady = false;
      onConnectionChanged?.call(false);
      onError?.call('On-device model initialization failed: $e');
      return false;
    }
  }

  Future<void> initCamera() async {
    if (kIsWeb) {
      onError?.call(
        'Offline sign model is currently supported on Android/iOS only.',
      );
      throw UnsupportedError('Offline sign model is not available on web.');
    }

    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      onError?.call('No camera available on this device.');
      throw StateError('No camera available');
    }

    final selected = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    final preferredFormat =
        defaultTargetPlatform == TargetPlatform.iOS
            ? ImageFormatGroup.bgra8888
            : ImageFormatGroup.nv21;

    _cameraController = CameraController(
      selected,
      ResolutionPreset.low,
      enableAudio: false,
      imageFormatGroup: preferredFormat,
    );

    try {
      await _cameraController!.initialize();
    } catch (_) {
      // Some Android devices cannot stream NV21 directly. Fall back to YUV420.
      if (preferredFormat == ImageFormatGroup.nv21) {
        await _cameraController!.dispose();
        _cameraController = CameraController(
          selected,
          ResolutionPreset.low,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.yuv420,
        );
        await _cameraController!.initialize();
      } else {
        rethrow;
      }
    }

    try {
      await _cameraController!.setFlashMode(FlashMode.off);
    } catch (_) {
      // Ignore unsupported flash controls for this stream format.
    }
  }

  Future<void> startStreaming() async {
    final ready = await loadModel();
    if (!ready) {
      throw StateError('Model is not ready');
    }

    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      await initCamera();
    }

    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      throw StateError('Camera failed to initialize');
    }

    if (controller.value.isStreamingImages) {
      _isStreaming = true;
      return;
    }

    _isStreaming = true;
    _isProcessingFrame = false;
    _incomingFrameCount = 0;
    _dynamicFrameSkip = _minFrameSkip;
    _lastProcessedAt = DateTime.fromMillisecondsSinceEpoch(0);

    _processedFramesTotal = 0;
    _droppedFramesTotal = 0;
    _metricsWindowProcessed = 0;
    _metricsWindowStart = DateTime.now();

    await controller.startImageStream(_handleCameraImage);
  }

  void _handleCameraImage(CameraImage image) {
    if (!_isStreaming || !_isModelReady) {
      return;
    }

    _incomingFrameCount += 1;
    if (_incomingFrameCount % _dynamicFrameSkip != 0) {
      return;
    }

    final now = DateTime.now();
    if (now.difference(_lastProcessedAt) < _minProcessInterval) {
      return;
    }

    if (_isProcessingFrame) {
      _droppedFramesTotal += 1;
      _emitMetrics(now);
      return;
    }

    final inputImage = _toInputImage(image);
    if (inputImage == null) {
      _droppedFramesTotal += 1;
      _emitMetrics(now);
      return;
    }

    final brightness = _estimateBrightness(image);
    final lowLight = brightness < _lowLightThreshold;

    _isProcessingFrame = true;
    _lastProcessedAt = now;
    unawaited(
      _processFrame(
        inputImage,
        frameWidth: image.width.toDouble(),
        frameHeight: image.height.toDouble(),
        ambientBrightness: brightness,
        lowLight: lowLight,
      ),
    );
  }

  Future<void> _processFrame(
    InputImage inputImage, {
    required double frameWidth,
    required double frameHeight,
    required double ambientBrightness,
    required bool lowLight,
  }) async {
    try {
      final detector = _poseDetector;
      if (detector == null) {
        throw StateError('Pose detector is not initialized.');
      }

      final poses = await detector.processImage(inputImage);
      final pose = poses.isNotEmpty ? poses.first : null;

      final handsDetected = _hasHands(pose);
      final faceDetected = _hasFace(pose);

      if (_featureRing.isEmpty) {
        throw StateError('Model buffers are not initialized.');
      }

      final row = _featureRing[_sequenceWriteIndex];
      _fillFeatureVector(
        pose,
        frameWidth: frameWidth,
        frameHeight: frameHeight,
        out: row,
      );

      _sequenceWriteIndex = (_sequenceWriteIndex + 1) % _sequenceLength;
      if (_sequenceCount < _sequenceLength) {
        _sequenceCount += 1;
      }

      final status = SignDetectionStatus(
        handsDetected: handsDetected,
        faceDetected: faceDetected,
        lowLight: lowLight,
        ambientBrightness: ambientBrightness,
        framesCollected: _sequenceCount,
        framesNeeded: _sequenceLength,
      );

      final canInfer = _sequenceCount == _sequenceLength && handsDetected;
      if (!canInfer) {
        onStatus?.call(status);
        return;
      }

      final probabilities = _runInference();
      if (probabilities.isEmpty) {
        onStatus?.call(status);
        return;
      }

      final accepted = _smoother.update(probabilities);
      if (accepted == null) {
        onStatus?.call(status);
        return;
      }

      final word =
          accepted.index >= 0 && accepted.index < _labels.length
              ? _labels[accepted.index]
              : 'unknown';

      if (_sentence.isEmpty || _sentence.last != word) {
        _sentence.add(word);
        if (_sentence.length > 10) {
          _sentence.removeAt(0);
        }
      }

      onPrediction?.call(
        SignDetectionResult(
          word: word,
          confidence: accepted.confidence,
          sentence: _sentence.join(' '),
          allProbs: _buildProbabilityMap(probabilities),
          handsDetected: handsDetected,
          faceDetected: faceDetected,
          lowLight: lowLight,
          ambientBrightness: ambientBrightness,
          framesCollected: _sequenceCount,
          framesNeeded: _sequenceLength,
        ),
      );
    } catch (e) {
      final message = e.toString().toLowerCase();
      if (message.contains('failed precondition')) {
        _preconditionErrorBurst += 1;
        final recovered = await _recoverFromPreconditionFailure();
        final note =
            recovered ? ' (Auto-recovered detector; continue signing.)' : '';
        onError?.call('On-device frame processing failed: $e$note');
      } else {
        _preconditionErrorBurst = 0;
        onError?.call('On-device frame processing failed: $e');
      }
    } finally {
      _processedFramesTotal += 1;
      _metricsWindowProcessed += 1;
      _emitMetrics(DateTime.now());
      _isProcessingFrame = false;
    }
  }

  InputImage? _toInputImage(CameraImage image) {
    final controller = _cameraController;
    if (controller == null) {
      return null;
    }

    final rotation = InputImageRotationValue.fromRawValue(
      controller.description.sensorOrientation,
    );
    if (rotation == null) {
      return null;
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      if (image.planes.isEmpty) {
        return null;
      }

      final plane = image.planes.first;
      final metadata = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: InputImageFormat.bgra8888,
        bytesPerRow: plane.bytesPerRow,
      );
      return InputImage.fromBytes(bytes: plane.bytes, metadata: metadata);
    }

    if (image.planes.isEmpty) {
      return null;
    }

    Uint8List? bytes;
    var bytesPerRow = image.width;
    if (image.format.group == ImageFormatGroup.nv21 &&
        image.planes.length == 1) {
      final plane = image.planes.first;
      bytes = plane.bytes;
      bytesPerRow = plane.bytesPerRow;
    } else if (image.format.group == ImageFormatGroup.yuv420 &&
        image.planes.length >= 3) {
      bytes = _convertYuv420ToNv21(image);
      bytesPerRow = image.width;
    }

    if (bytes == null) {
      return null;
    }

    final expectedBytes = image.width * image.height * 3 ~/ 2;
    if (bytes.length < expectedBytes) {
      return null;
    }

    final metadata = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      format: InputImageFormat.nv21,
      bytesPerRow: bytesPerRow,
    );

    return InputImage.fromBytes(bytes: bytes, metadata: metadata);
  }

  Uint8List _convertYuv420ToNv21(CameraImage image) {
    final width = image.width;
    final height = image.height;
    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    final output = Uint8List(width * height + (width * height ~/ 2));
    var outIndex = 0;

    // Copy Y plane while honoring row stride.
    for (var row = 0; row < height; row++) {
      final yRowStart = row * yPlane.bytesPerRow;
      final yRowEnd = yRowStart + width;
      if (yRowEnd > yPlane.bytes.length || outIndex + width > output.length) {
        break;
      }
      output.setRange(outIndex, outIndex + width, yPlane.bytes, yRowStart);
      outIndex += width;
    }

    final chromaHeight = height ~/ 2;
    final chromaWidth = width ~/ 2;
    final uPixelStride = uPlane.bytesPerPixel ?? 1;
    final vPixelStride = vPlane.bytesPerPixel ?? 1;

    // Interleave V and U bytes to produce NV21 (VU) layout.
    for (var row = 0; row < chromaHeight; row++) {
      final uRowStart = row * uPlane.bytesPerRow;
      final vRowStart = row * vPlane.bytesPerRow;
      for (var col = 0; col < chromaWidth; col++) {
        final uIndex = uRowStart + col * uPixelStride;
        final vIndex = vRowStart + col * vPixelStride;
        if (uIndex >= uPlane.bytes.length || vIndex >= vPlane.bytes.length) {
          continue;
        }
        if (outIndex + 1 >= output.length) {
          break;
        }
        output[outIndex++] = vPlane.bytes[vIndex];
        output[outIndex++] = uPlane.bytes[uIndex];
      }
    }

    return output;
  }

  void _fillFeatureVector(
    Pose? pose, {
    required double frameWidth,
    required double frameHeight,
    required List<double> out,
  }) {
    out.fillRange(0, out.length, 0.0);
    if (pose == null) {
      return;
    }

    final safeWidth = math.max(1.0, frameWidth);
    final safeHeight = math.max(1.0, frameHeight);

    // Model expects first 132 values to be 33 pose landmarks * 4 channels.
    for (var i = 0; i < _poseOrder.length; i++) {
      final landmark = pose.landmarks[_poseOrder[i]];
      if (landmark == null) {
        continue;
      }

      final offset = i * 4;
      if (offset + 3 >= out.length) {
        break;
      }

      out[offset] = (landmark.x / safeWidth).clamp(0.0, 1.0);
      out[offset + 1] = (landmark.y / safeHeight).clamp(0.0, 1.0);
      out[offset + 2] = (landmark.z / safeWidth).clamp(-1.0, 1.0);
      out[offset + 3] = 1.0;
    }
  }

  List<double> _runInference() {
    final interpreter = _interpreter;
    if (interpreter == null || _sequenceCount < _sequenceLength) {
      return const <double>[];
    }
    if (_modelInput.isEmpty || _modelOutput.isEmpty || _featureRing.isEmpty) {
      return const <double>[];
    }

    final oldest = _sequenceWriteIndex;
    final inputTensor = <List<List<double>>>[
      List<List<double>>.generate(_sequenceLength, (i) {
        final src = (oldest + i) % _sequenceLength;
        return List<double>.from(_featureRing[src], growable: false);
      }, growable: false),
    ];

    final outputTensor = <List<double>>[
      List<double>.filled(_modelOutput.first.length, 0.0, growable: false),
    ];

    interpreter.run(inputTensor, outputTensor);
    _modelOutput.first.setAll(0, outputTensor.first);
    return _modelOutput.first;
  }

  Map<String, double> _buildProbabilityMap(List<double> probabilities) {
    final map = <String, double>{};
    final length = math.min(_labels.length, probabilities.length);
    for (var i = 0; i < length; i++) {
      map[_labels[i]] = probabilities[i];
    }
    return map;
  }

  bool _hasHands(Pose? pose) {
    if (pose == null) {
      return false;
    }

    return pose.landmarks[PoseLandmarkType.leftWrist] != null ||
        pose.landmarks[PoseLandmarkType.rightWrist] != null ||
        pose.landmarks[PoseLandmarkType.leftIndex] != null ||
        pose.landmarks[PoseLandmarkType.rightIndex] != null;
  }

  bool _hasFace(Pose? pose) {
    if (pose == null) {
      return false;
    }

    return pose.landmarks[PoseLandmarkType.nose] != null ||
        pose.landmarks[PoseLandmarkType.leftEye] != null ||
        pose.landmarks[PoseLandmarkType.rightEye] != null;
  }

  double _estimateBrightness(CameraImage image) {
    if (image.planes.isEmpty) {
      return 60.0;
    }

    final luma = image.planes.first.bytes;
    if (luma.isEmpty) {
      return 60.0;
    }

    var sum = 0;
    var count = 0;

    // Sparse sampling keeps this cheap in the camera callback.
    for (var i = 0; i < luma.length; i += 12) {
      sum += luma[i];
      count += 1;
    }

    if (count == 0) {
      return 60.0;
    }

    return sum / count;
  }

  Future<Map<String, dynamic>> _loadManifest() async {
    try {
      final raw = await rootBundle.loadString(_manifestAssetPath);
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  List<String> _parseLabels(String labelMapRaw) {
    final decoded = jsonDecode(labelMapRaw);

    if (decoded is List) {
      return decoded
          .map((e) => e.toString())
          .where((e) => e.trim().isNotEmpty)
          .toList();
    }

    if (decoded is Map) {
      final pairs = <MapEntry<String, int>>[];
      decoded.forEach((key, value) {
        if (value is num) {
          pairs.add(MapEntry(key.toString(), value.toInt()));
        }
      });
      pairs.sort((a, b) => a.value.compareTo(b.value));
      return pairs.map((e) => e.key).toList();
    }

    return <String>[];
  }

  List<String> _normalizeLabels(List<String> labels, int classCount) {
    if (labels.length == classCount) {
      return labels;
    }

    if (labels.isEmpty) {
      return List<String>.generate(classCount, (i) => 'class_$i');
    }

    if (labels.length > classCount) {
      return labels.take(classCount).toList();
    }

    final normalized = List<String>.from(labels);
    for (var i = labels.length; i < classCount; i++) {
      normalized.add('class_$i');
    }
    return normalized;
  }

  int _readOutputClassCount() {
    try {
      final shape = _interpreter?.getOutputTensor(0).shape;
      if (shape == null || shape.isEmpty) {
        return 0;
      }
      return shape.last;
    } catch (_) {
      return 0;
    }
  }

  List<int>? _readInputTensorShape() {
    try {
      final interp = _interpreter;
      if (interp == null) return null;
      final tensors = interp.getInputTensors();
      if (tensors.isEmpty) return null;
      final shape = tensors.first.shape;
      if (shape.length < 3) return null;
      return shape;
    } catch (_) {
      return null;
    }
  }

  Future<bool> _recoverFromPreconditionFailure() async {
    if (_preconditionErrorBurst < 2) {
      return false;
    }

    final now = DateTime.now();
    if (now.difference(_lastPoseDetectorResetAt) < const Duration(seconds: 2)) {
      return false;
    }

    _lastPoseDetectorResetAt = now;
    _preconditionErrorBurst = 0;

    final previous = _poseDetector;
    try {
      _poseDetector = PoseDetector(
        options: PoseDetectorOptions(mode: PoseDetectionMode.stream),
      );
      if (previous != null) {
        await previous.close();
      }
      resetSession();
      return true;
    } catch (_) {
      _poseDetector = previous;
      return false;
    }
  }

  void _initializeBuffers(int classCount) {
    _featureRing = List<List<double>>.generate(
      _sequenceLength,
      (_) => List<double>.filled(_featureSize, 0.0, growable: false),
      growable: false,
    );
    _orderedSequence = List<List<double>>.generate(
      _sequenceLength,
      (_) => _featureRing.first,
      growable: false,
    );
    _modelInput = <List<List<double>>>[_orderedSequence];
    _modelOutput = <List<double>>[
      List<double>.filled(math.max(1, classCount), 0.0, growable: false),
    ];
    _sequenceWriteIndex = 0;
    _sequenceCount = 0;
  }

  void _emitMetrics(DateTime now) {
    final elapsedMs = now.difference(_metricsWindowStart).inMilliseconds;
    if (elapsedMs < 1000) {
      return;
    }

    final elapsedSec = elapsedMs / 1000.0;
    final fps = elapsedSec <= 0 ? 0.0 : _metricsWindowProcessed / elapsedSec;

    onMetrics?.call(
      SignStreamMetrics(
        outgoingFps: fps,
        sentFrames: _processedFramesTotal,
        droppedFrames: _droppedFramesTotal,
      ),
    );

    // Keep high-end devices accurate (lower skip), and low-end devices smooth.
    if (fps < 5.0 && _dynamicFrameSkip < _maxFrameSkip) {
      _dynamicFrameSkip += 1;
    } else if (fps > 11.0 && _dynamicFrameSkip > _minFrameSkip) {
      _dynamicFrameSkip -= 1;
    }

    _metricsWindowStart = now;
    _metricsWindowProcessed = 0;
  }

  void stopStreaming() {
    _isStreaming = false;
    _incomingFrameCount = 0;
    _isProcessingFrame = false;

    final controller = _cameraController;
    if (controller != null && controller.value.isStreamingImages) {
      unawaited(
        controller.stopImageStream().catchError((_) {
          // Ignore transient stop failures during quick toggles.
        }),
      );
    }
  }

  void resetSession() {
    _sequenceWriteIndex = 0;
    _sequenceCount = 0;
    for (final row in _featureRing) {
      row.fillRange(0, row.length, 0.0);
    }
    _sentence.clear();
    _smoother.reset();
  }

  void disconnect() {
    stopStreaming();
    resetSession();
  }

  void dispose() {
    stopStreaming();

    final controller = _cameraController;
    _cameraController = null;
    if (controller != null) {
      unawaited(controller.dispose());
    }

    final detector = _poseDetector;
    _poseDetector = null;
    if (detector != null) {
      unawaited(detector.close());
    }

    _interpreter?.close();
    _interpreter = null;

    _isModelReady = false;
    onConnectionChanged?.call(false);
  }
}

final signLanguageServiceProvider = Provider<SignLanguageService>((ref) {
  final service = SignLanguageService();
  ref.onDispose(service.dispose);
  return service;
});
