# Ishara App – Full Feature Implementation Plan

## App Architecture Summary
- **Framework**: Flutter (Dart), Riverpod state management, GoRouter navigation
- **Backend**: Node.js/Express + MongoDB Atlas (deployed on Vercel)
- **ML**: TFLite V6 model for Arabic Sign Language (12 signs), ML Kit for OCR/object detection

---

## 1. Sign Language AI Integration (Translation Page)

**Exported model**: `asl_v6.tflite` (5.7MB), 12 Arabic signs, input `[1, 30, 1692]` (30 frames × 1692 MediaPipe keypoints)

**Problem**: MediaPipe Holistic is NOT available as a Flutter plugin. The model needs 1692 keypoints per frame.

**Solution**: Implement a simplified on-device pipeline:
- Use `google_mlkit_pose_detection` for 33 pose landmarks (×4 = 132 values)
- Zero-pad face/hand landmarks (since no Flutter plugin exists)
- Feed simplified keypoints to the LSTM model
- Apply temporal smoothing (matching Python `TemporalSmoother`)
- Display detected signs with confidence scores

**Files to create/modify**:
- Copy model assets to `assets/models/`
- New: `sign_language_service.dart` – TFLite + keypoint pipeline
- Modify: `translator_controller.dart` – wire camera → detection → display
- Modify: `esl_translator_service.dart` – replace stub with real model

---

## 2. UI Polish

Already good design system. Polish:
- Audit `withOpacity()` deprecation warnings
- Ensure 48dp touch targets
- Add missing loading/empty states
- Verify dark/light mode consistency
- Smooth entrance animations

---

## 3. Database Verification

Backend at `https://isharagrad.vercel.app`. DataService has full CRUD:
- Test health, auth, profile, contact endpoints
- Add retry logic with exponential backoff
- Add offline caching via Hive

---

## 4. Learning Hub Videos

All lessons have `videoUrl: null`. Replace with real ArSL video URLs from YouTube.
Add lesson detail screen with video player.

---

## 5. Emergency Contact – WhatsApp & Telegram

Existing code uses deep-links. Fixes needed:
- Fix Telegram URI (`tg://msg?to=` → `https://t.me/+phone`)
- Add WhatsApp web fallback (`https://wa.me/phone`)
- Wire into SOS flow
- Add emergency contact setup dialog

---

## 6. Vision Page – Advanced CV

Enhance currency detection with EGP-specific patterns:
- Arabic numeral conversion
- Denomination pattern matching
- Object detection with TTS
- Real-time camera mode

---

## IMPORTANT QUESTIONS FOR YOU

1. **Sign Language**: The model needs MediaPipe Holistic (not available in Flutter). I'll implement a simplified on-device approach with degraded accuracy. OK?

2. **Videos**: Do you have specific video files/URLs for Learning Hub? Or should I use YouTube ArSL tutorial videos?

3. **Database**: MongoDB connection string has no database name. Should it be `ishara` or something else?

4. **Server**: Is `https://isharagrad.vercel.app` currently running?
