# Ishara

Ishara is an accessible ESL (sign language) assistant and safety companion for Android and iOS. It provides ESL ↔ Arabic translation, STT/TTS, vision tools (OCR, currency), obstacle detection, SOS, a sign learning hub, and hardware pairing with ESP32 devices.

## Setup

### 1. Install dependencies

Use **`flutter pub get`** to fetch packages (do **not** use `flutter pub run`; that command runs an executable and requires a target, e.g. `dart run flutter_launcher_icons`).

```bash
cd ishara
flutter pub get
```

### 2. App icon (Ishara logo)

The app logo is at `assets/images/ishara_app_logo.png`. To regenerate Android/iOS launcher icons from it:

```bash
dart run flutter_launcher_icons
```

### 3. Run the app

```bash
flutter run
```

## Architecture overview

- **State:** Riverpod (`StateNotifier` / providers).
- **Navigation:** `go_router` with `ShellRoute` and bottom nav (Communicate, Vision, Safety, Learning, Profile).
- **Theme:** Ishara teal/orange palette, light/dark, RTL support (EN/AR).
- **Features:**
  - **Communicate:** ESL ↔ Arabic translation (stub/TFLite), STT/TTS, quick phrases.
  - **Vision:** OCR (ML Kit), currency detection, object recognition.
  - **Safety:** Simulated/hardware obstacle data, SOS flow (arm → countdown → send location).
  - **Learning:** Lessons and ESL dictionary (in-memory/backend-ready), search and categories.
  - **Profile:** Theme/language toggles, link to hardware pairing.
  - **Hardware pairing:** WebSocket client for ESP32 (IP + port), connect/disconnect, state stream.

## Hardware pairing (ESP32)

1. Open **Profile** → **Pair hardware**.
2. Enter the device IP and port (e.g. ESP32 in AP mode: `192.168.4.1`, port `8080`).
3. Tap **Connect**. The app uses WebSocket messages: `sensor_update`, `event`, `command` (e.g. `vibrate`).

Protocol: JSON envelope with `type`, `id`, `payload`. See `lib/src/core/hardware/hardware_connection_service.dart`.

## Model update (ESL TFLite)

- Export script: `scripts/export_app_model.py` (from V6): lists vocabulary, add/remove by index, exports TFLite + `label_map_v6.json` + `manifest.json` into `ishara/assets/models/`.
- The app loads the stub translator by default; wire `StubEslTranslator` to the real TFLite model when `asl_v6.tflite` and metadata are present in assets.

## Testing

```bash
flutter test
```

Unit tests: translator, safety controller, hardware message parsing. Widget tests: Communicate screen, Safety screen (dashboard + SOS semantics).

## Accessibility

- Semantics on SOS and main actions (e.g. “Open SOS emergency screen”).
- Large touch targets and flexible layouts for small screens.
- Theme supports light/dark and RTL (Arabic).

## Dependencies

Key packages: `flutter_riverpod`, `go_router`, `dio`, `camera`, `permission_handler`, `image_picker`, `connectivity_plus`, `flutter_tts`, `speech_to_text`, `tflite_flutter`, `google_mlkit_text_recognition`, `geolocator`, `web_socket_channel`, `hive`, `hive_flutter`, `vibration`.
