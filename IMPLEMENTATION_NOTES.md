# Ishara — Implementation Notes (Big Refactor)

This document summarises everything wired up in the recent multi-phase
implementation, together with the manual steps you still need to take to
finish (model training data, API keys, asset videos).

## Phase 0 — Preflight ✅
- `pubspec.yaml`: added `share_plus`, `cached_network_image`, `shimmer`,
  `lottie`, `fl_chart`, `chewie`, `image`, `flutter_secure_storage`,
  `another_telephony`, `flutter_local_notifications`, `device_info_plus`,
  `collection`, `uuid`, `intl`. New asset folders for `assets/videos/signs/`,
  `assets/sign_dictionary.json`, `assets/products/`.
- AndroidManifest: SMS, location (incl. background), notifications,
  foreground services, query intents for WhatsApp/Telegram/SMS.
- iOS Info.plist: mic / location / photo / speech / background-mode keys
  and `LSApplicationQueriesSchemes` for whatsapp/tg/sms/mailto/tel.
- Removed legacy movie-app remnants from `lib/`.

## Phase 1 — Auth + MongoDB ✅
- `User` schema extended: multi `emergencyContacts` with `app/priority/
  telegramChatId`, `socialLinks`, `accessibilityPrefs`, `cart`. `disabilityType`
  enum no longer accepts `hearing`. Defaults to `deaf`.
- `userValidator.js` updated likewise.
- New routes mounted in `app.js`:
  - `/api/products`, `/api/reviews`, `/api/cart`, `/api/orders`
  - `/api/sos`, `/api/chatbot`, `/api/social`, `/api/accessibility`,
    `/api/quiz`
- New models: `Product`, `Review`, `Order`, `SosEvent`, `QuizAttempt`.
- `services/messaging.js` — Twilio (WhatsApp+SMS) and Telegram Bot dispatchers.
- `scripts/seedProducts.js` — 8 example accessibility products.

**Required env keys** (drop into `server/.env`):
```
MONGO_URI=...
JWT_SECRET=...
GEMINI_API_KEY=...               # chatbot
TWILIO_ACCOUNT_SID=...
TWILIO_AUTH_TOKEN=...
TWILIO_WHATSAPP_FROM=whatsapp:+14155238886
TWILIO_SMS_FROM=+1...
TELEGRAM_BOT_TOKEN=...
VENDOR_WHATSAPP=+201...           # default checkout vendor
```

## Phase 2 — Translator ✅
- Existing `sign_language_service.dart` already runs the V6 TFLite. Default
  translator stays on-device (per your decision).
- **NEW**: Arabic-text → Sign clip player (`text_to_sign_screen.dart`).
- **NEW**: `assets/sign_dictionary.json` mapping Arabic words & per-letter
  finger-spelling clip paths. *Drop your `.mp4` clips into
  `assets/videos/signs/` (and `assets/videos/signs/letters/`) using the file
  names referenced in the JSON.*
- **NEW**: `core/services/tts_service.dart` — global TTS, replaces
  per-feature singletons.

## Phase 3 — Vision ✅
- `currency_classifier.dart` — bundled-TFLite first; ML-Kit keyword fallback
  with `keywordToDenomination`. Exposes `tally`, `sumEgp`, `formatTotal`.
- `imagenet_classifier.dart` — fine-grained 1000-class classifier.
- **NEW**: `scripts/train_egp_classifier.py` — fine-tune MobileNetV2 on a
  Roboflow EGP dataset and export the TFLite artefact. Drop the resulting
  file at `assets/models/currency_egp.tflite`.
- For ImageNet: download a public quantised MobileNetV3-Large TFLite + labels
  and place at `assets/models/mobilenet_v3_large.tflite` and
  `assets/models/imagenet_labels.txt`.

## Phase 4 — Multi-contact silent SOS ✅
- `contacts_repository.dart` — server-backed multi-contact CRUD with offline
  cache.
- `sos_coordinator.dart` — fires **in parallel**:
  1. `another_telephony` silent SMS to every contact (Android only).
  2. `POST /api/sos` so the server runs Twilio WhatsApp + Telegram Bot.
  3. WhatsApp deep-link as last-resort fallback.
- `contacts_screen.dart` — full UI to add/edit/delete contacts and choose
  which channels each contact receives.

## Phase 5 — Learning Hub + Duolingo Quiz ✅
- `quiz_screen.dart` — clip→word, word→clip modes implemented; perform-sign
  hooks reserved for the existing translator pipeline; XP/hearts/streak.
- Logs every attempt to `/api/quiz`; profile shows aggregated XP/streak.
- Learning screen now exposes a "Quiz" floating button.

## Phase 6 — Shop ✅
- `domain/product_models.dart` — `Product`, `CartItem`, `Review`.
- `data/shop_repository.dart` — products, cart, reviews, checkout.
- Screens: `products_screen`, `product_detail_screen` (with star rating &
  review composer), `cart_screen` (qty steppers, WhatsApp checkout).
- Backend `POST /api/orders/checkout` returns a pre-filled WhatsApp URL with
  the order summary.

## Phase 7 — Chatbot ✅
- Server proxy `chatbotRoutes.js` calling Gemini 1.5 Flash with a system
  prompt describing every Ishara feature. Returns `[open:route]` tags so
  replies become tappable deep-links.
- `assistant_screen.dart` — chat UI with quick-reply chips, TTS read-back,
  and tap-to-route on tagged replies.

## Phase 8 — Social linking + share_plus ✅
- `social_links_screen.dart` — edit Instagram/Facebook/Twitter/TikTok/
  WhatsApp/YouTube; saves to `/api/social`.
- `core/widgets/share_button.dart` — drop-in share action used across product
  detail, translator results, vision OCR, learning words.

## Phase 9 — Accessibility expansion ✅
- `core/settings/accessibility_settings.dart` — full Riverpod controller.
- `accessibility_settings_screen.dart` — toggles for Auto-TTS, high contrast,
  3 color-blind palettes, dyslexia font, text scale 80–200 %, motor mode,
  reduce motion, haptics, vibration intensity, sign-lang preferred.
- `main.dart` now wires these settings into the `MaterialApp`'s textScale and
  applies the high-contrast / colour-blind palette via
  `applyAccessibilityToTheme()`.

## Phase 10 — UI polish ✅
- New routes wired into `app_router.dart` and discoverable from the Profile
  screen action list (Accessibility, Contacts, Social Links, Shop, Assistant).
- Existing translator/learning/safety screens get FAB + entry points to the
  new flows.

## Phase 11 — DB CRUD verification (manual)
Run after deploying the server:

```bash
# 1. Seed
node server/scripts/seedProducts.js

# 2. Smoke tests via curl/Postman
curl -X POST $BASE/api/auth/register -d '{"email":"a@b.c","password":"abc12345","name":"Tester","disabilityType":"deaf"}' -H 'Content-Type: application/json'
curl -X POST $BASE/api/auth/login -d '{"email":"a@b.c","password":"abc12345"}'

# Then with the JWT
curl -H "Authorization: Bearer $TOKEN" $BASE/api/products
curl -H "Authorization: Bearer $TOKEN" -X POST $BASE/api/cart -d '{"productId":"...","qty":1}' -H 'Content-Type: application/json'
curl -H "Authorization: Bearer $TOKEN" -X POST $BASE/api/users/emergency-contacts -d '{"name":"Mum","phone":"+20111...","app":"all"}' -H 'Content-Type: application/json'
curl -H "Authorization: Bearer $TOKEN" -X POST $BASE/api/sos -d '{"location":{"lat":30.04,"lng":31.23}}' -H 'Content-Type: application/json'
```

## Phase 12 — Bug sweep (post `flutter pub get`)

After `flutter pub get`, run:

```
flutter analyze
flutter test
```

The current diagnostics about `another_telephony`, `share_plus`, and
`cached_network_image` will resolve once pub fetches the packages.

## Outstanding actions you (the user) need to take

1. **Drop ArSL clips** into `assets/videos/signs/` (12 word clips + 28 letter
   clips) using the names listed in `assets/sign_dictionary.json`.
2. **Train and bundle** `currency_egp.tflite` (use the new training script).
3. **Download MobileNetV3-Large** TFLite + ImageNet labels and put them in
   `assets/models/`.
4. **Provide API keys** in `server/.env` for Gemini, Twilio, Telegram Bot.
5. **Deploy backend** (Render / Railway / Vercel) and pass the URL via
   `--dart-define=API_BASE_URL=https://<host>` for production builds.
6. **Add fonts** (`Tajawal`, `OpenDyslexic`) under `assets/fonts/` and
   register them in `pubspec.yaml` if you want the dyslexia-friendly toggle
   to swap fonts (currently it's a no-op visual flag).
