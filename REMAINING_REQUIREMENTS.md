# Ishara — Remaining Work + Bug-fix Plan

This is the canonical follow-up plan. It supersedes the earlier
requirements doc. Items marked **[NEW]** are the new bugs/tasks you
raised; **[CARRY]** are previously-listed partials still to do. Status
icons: ❌ broken, ⚠️ partial, 🆕 new task.

Critical bugs first (blockers), then carry-overs, then nice-to-haves.

---

## A. Critical bugs (blockers) — must fix before next demo

### A1. ❌ Sign translator stuck on "Camera stream temporarily desynchronized" [NEW]
**Symptom:** real device shows the banner indefinitely; restart-camera
does nothing. Recovery loop in `sign_language_service.dart` keeps
re-triggering because the precondition check is too aggressive after the
camera plugin emits frames slightly out of order on Samsung devices.

**Root cause (likely):**
- `_preconditionErrorBurst >= 2` triggers
  `_recoverFromPreconditionFailure`, which stops the image stream and
  immediately restarts it. On the SM-N975F (Note 10+) the new stream
  emits frames with timestamps earlier than the last frame of the
  previous stream → another precondition failure → infinite recovery.
- Pose detector latency (~120-180 ms on this device) > camera frame
  interval (60 ms at YUV_420_888) → back-pressure inside `_processFrame`.

**Fix plan:**
1. Replace binary "stop+start" recovery with a **circuit breaker**:
   first failure → drop next 6 frames; second consecutive → cool down
   500 ms; only third → full restart. Resets after 30 successful frames.
2. Add **frame-skipping** at camera-stream level: if `_processing == true`,
   discard immediately (don't queue).
3. Switch image format to `ImageFormatGroup.nv21` on Android.
4. Lower frame-rate cap to 8 fps on devices with `devicePixelRatio >= 3`.
5. Surface a manual **"Reset model"** button on the translator screen.
6. Log every recovery cycle via `dart:developer.log('translator', …)`.

**Files:** `sign_language_service.dart`, `translator_controller.dart`.

**Verify:** translator on SM-N975F starts producing detections within 5 s
and never shows the desync banner unless camera is physically gone.

---

### A2. ❌ In-app SOS button does nothing [NEW]
**Symptom:** tapping the big SOS button on the Safety screen has no
effect — no countdown, no SMS, no API call.

**Root cause:** `safety_screen.dart` was wired to the legacy
single-contact `EmergencyContact.load()`. After Phase 4 the new
`SosCoordinator` was built but the button was never rewired. It currently
calls a path that early-returns when the legacy single-contact prefs are
empty (which they always are now that contacts live in MongoDB).

**Fix plan:**
1. In `safety_controller.dart`, add `armSos()`:
   - `HapticFeedback.heavyImpact()` × 3
   - 5-second countdown (cancellable)
   - Expiry → `ref.read(sosCoordinatorProvider).dispatch()`
2. `safety_screen.dart` SOS button `onPressed` → `controller.armSos()`.
3. Full-screen overlay during countdown with a **big cancel button**.
4. Stream per-channel result chips (SMS sent / WhatsApp sent / Telegram
   sent) as the dispatch resolves.
5. If no contacts exist, snackbar + push `/profile/contacts`.
6. Speak the result via TTS so blind users know it went out.

**Files:** `safety_screen.dart`, `safety_controller.dart`.

**Verify:** with at least one contact, tap SOS → countdown overlay → 5 s
later "Sent to N contacts" → SMS arrives on Android, server `/api/sos`
shows the row.

---

### A3. ⚠️ Sign-language model accuracy [CARRY → upgraded]
The V6 model expects Holistic features (1692-dim); Flutter only feeds
pose (132-dim padded with zeros). Even after A1, accuracy is poor.

**Decision: BOTH paths.** Profile setting "Use cloud sign translation"
toggles:
- **OFF (default, offline):** existing on-device pipeline.
- **ON:** new `RemoteSignService` opens a SocketIO/WebSocket connection
  to `server/sign_language_server/app.py`, sends base64 frames at 8 fps,
  receives `{label, confidence}` events.

**Files:** new `lib/src/features/translator/data/remote_sign_service.dart`,
edit `translator_controller.dart` to choose backend, new toggle in
`accessibility_settings.dart` (or its own setting), edit
`translator_providers.dart`.

**You must deploy** `sign_language_server` to a host (Render with GPU
add-on or a small VPS, ~$10-20/mo). Set
`SIGN_SERVER_URL=wss://your-host` in Flutter via `--dart-define`.

---

### A4. ❌ Arabic ↔ English language switching is incomplete [NEW]
**Symptom:** locale toggle in Profile only re-renders some screens; many
strings are hardcoded in English. RTL doesn't always flip.

**Root cause:** `translations.dart` only has keys for the original
screens. New screens (shop, assistant, accessibility, contacts, social,
quiz, text-to-sign) were written with English literals. The wrapping
`Directionality` in `main.dart` is hardcoded to LTR.

**Fix plan:**
1. Add ~80 keys to `translations.dart` covering every new screen.
2. Convert every `Text('Foo')` in new code to `Text(s.foo)`.
3. In `main.dart` derive `Directionality.textDirection` from active
   locale (`ar` → RTL, `en` → LTR).
4. Replace any wrong `EdgeInsets`/`Alignment.topLeft` with directional
   variants (`EdgeInsetsDirectional`, `AlignmentDirectional.topStart`).
5. Sweep all `AppBar(title: const Text('English title'))` headers.
6. Add a smoke test that loads each screen under both locales.

**Files:** `translations.dart` (large expansion), every new screen,
`main.dart`.

**Verify:** flip toggle → every screen Arabic + RTL within one frame; no
hardcoded English visible when Arabic is active.

---

### A5. ❌ "Social Links" was pointed the wrong way — make it for Ishara, not the user [NEW]
**You meant** Ishara's brand social handles for users to follow Ishara.
I built a user-editable form by mistake.

**Fix plan:**
1. Drop user `socialLinks` UI; hide that schema block.
2. Replace `social_links_screen.dart` with a read-only **"Follow Ishara"**
   screen showing tap-to-open icons for Ishara's official Instagram /
   Facebook / Twitter / TikTok / YouTube / WhatsApp Business.
3. Hard-code in `lib/src/core/config/ishara_brand.dart` with placeholder
   handles (`@ishara_official`) and a clear comment block showing where
   to paste the real ones.
4. Update Profile screen entry to "Follow Ishara" (icon + tile).
5. Add a small "Follow us" footer on the Assistant screen too.
6. The user-content sharing rollout (`IsharaShareButton`) is still useful
   and stays.

**Files:** `social_links_screen.dart` (rewrite as read-only), new
`lib/src/core/config/ishara_brand.dart`, `profile_screen.dart`,
`assistant_screen.dart`.

---

### A6. ⚠️ Accessibility features need full redo [NEW]
**Audit:**
- ✅ Auto-TTS toggle persists & speaks → works.
- ✅ Text scale slider → works.
- ⚠️ High-contrast — only flips colorScheme; many widgets use
  `IsharaColors.tealLight` etc. and ignore it.
- ❌ Color-blind palettes — only `colorScheme.primary`; semantic
  colours unchanged.
- ❌ Dyslexia font — toggle does nothing; no font bundled.
- ⚠️ Motor mode — bumps `VisualDensity` only; touch targets sized in
  pixels stay the same.
- ❌ Reduce-motion — saved but no consumer.
- ❌ Haptics-on-every-action — saved but no central interceptor.
- ❌ "Prefer sign language" — saved but no consumer.

**Full redo:**
1. Centralise **theme tokens** through a Riverpod `colorTokensProvider`
   so high-contrast and color-blind palettes propagate everywhere
   (semantic colours included).
2. Bundle **OpenDyslexic** font (Regular + Bold) and swap `textTheme`
   `fontFamily` when the toggle is on.
3. **Motor mode:** new `MotorAware` wrapper enforcing 56×56 minimum hit
   targets, applied via the shell scaffold.
4. **Reduce-motion:** wire to `flutter_animate`'s global config so
   `.animate().fadeIn()` collapses to instant; disable hero animations.
5. **Haptics-on-every-action:** new `HapticsService`; wrap
   `GradientAuthButton`, nav taps, list items.
6. **Auto-TTS upgrade:** `AutoTtsScope` widget at shell level announces
   destination title + primary CTA on route change; pauses on TextField
   focus.
7. **"Prefer sign language":** opens Translator in sign-→text mode by
   default; Learning Hub auto-plays the matching clip on word detail.
8. New **`/profile/accessibility/preview`** screen rendering each
   toggle's effect side-by-side for visual QA.

**Files:** `accessibility_settings.dart`, `ishara_theme.dart`, new
`haptics_service.dart`, `motor_aware.dart`, `auto_tts_scope.dart`, new
`accessibility_preview_screen.dart`, every screen with hardcoded
`IsharaColors.*` or animations.

**Verify:** every toggle produces an immediate observable effect on the
preview screen and across the rest of the app.

---

## B. Profile flow — small but visible

### B1. 🆕 Profile photo step after OTP (skippable) [NEW]
**Plan:**
1. After OTP success, push a new `ProfilePhotoSetupScreen`
   (one-time only).
2. Buttons: **Choose photo** (gallery), **Take photo** (camera),
   **Skip for now**.
3. Either action → Home; on skip the user keeps the default avatar.
4. Profile tab shows a dismissible "Add a profile photo" banner until
   they add one or dismiss it.
5. No feature is gated on having a photo.

**Files:** new `profile_photo_setup_screen.dart`, edit `otp_screen.dart`
to route there post-verify, banner in `profile_screen.dart`.

---

## C. Carry-overs — still needed

### C1. ⚠️ Sign-clip videos (12 word + 28 letter MP4s) [CARRY]
Drop into `assets/videos/signs/` and `assets/videos/signs/letters/`
matching names in `assets/sign_dictionary.json`. Without these the
Text-→Sign and Quiz screens look empty.

### C2. ⚠️ EGP currency TFLite [CARRY]
Train via `python scripts/train_egp_classifier.py --data data/egp`. Drop
to `assets/models/currency_egp.tflite`. Wire `CurrencyClassifier` into
`vision_controller.dart`.

### C3. ⚠️ ImageNet MobileNetV3-Large TFLite [CARRY]
Drop `mobilenet_v3_large.tflite` + `imagenet_labels.txt` into
`assets/models/`. Wire `ImagenetClassifier`.

### C4. ⚠️ Twilio + Telegram + Gemini env keys [CARRY]
Without them, server-side dispatch and chatbot are dark. See env block
in §C5.

### C5. ⚠️ Server deployment [CARRY]
Render / Railway / Vercel. `.env` keys:
```
MONGO_URI=mongodb+srv://...
JWT_SECRET=<32+ chars>
PORT=4000
SMTP_HOST=...
SMTP_USER=...
SMTP_PASS=...
GEMINI_API_KEY=...
TWILIO_ACCOUNT_SID=...
TWILIO_AUTH_TOKEN=...
TWILIO_WHATSAPP_FROM=whatsapp:+...
TWILIO_SMS_FROM=+...
TELEGRAM_BOT_TOKEN=123:abc...
VENDOR_WHATSAPP=+201...
ALLOWED_ORIGINS=https://your-domain.com
```
Then build with:
`flutter build apk --dart-define=API_BASE_URL=https://your-server.example.com`

### C6. ⚠️ Hardware foreground service [CARRY]
For SOS to fire from glasses while the app is backgrounded. ~half-day
task; manifest perms already added.

### C7. ⚠️ Quiz "Perform sign on camera" mode [CARRY]
Stubbed pending A3 model accuracy fix.

### C8. ⚠️ Share-buttons rollout [CARRY]
Drop `IsharaShareButton` into translator results, vision OCR panel,
learning word sheet, SOS history.

### C9. ⚠️ Theme deprecation cleanup [CARRY]
~268 `MaterialState`/`withOpacity` infos. Cosmetic.

### C10. ⚠️ Tajawal Arabic font [CARRY]
For polished Arabic typography. Drop `Tajawal-*.ttf` into
`assets/fonts/`, register, set Arabic-locale family in `ishara_theme.dart`.

### C11. ⚠️ Real payment gateway [CARRY]
Currently checkout opens WhatsApp with the order summary. Stripe / Paymob
integration is a separate ~1-day pass.

### C12. ⚠️ Social-login wiring [CARRY]
Google + Facebook deps bundled, integration not done. Needs OAuth client
IDs, Facebook App ID/Secret, and a `/api/auth/social` route.

---

## D. Build / run notes

### D0. Claude Code + skills setup (required on a new device)
This project was authored with Claude Code and depends on a number of
plugin "skills" for the agentic workflows (planning, sub-agents, UI/UX
review, Vercel deploys, etc.). If you check this repo out on a new
machine and want to keep iterating with Claude in the same way, you must
install the following on that machine:

1. **Claude Code CLI / IDE extension**
   - macOS / Linux:
     ```bash
     curl -fsSL https://claude.ai/install.sh | sh
     ```
   - Windows (PowerShell, Admin):
     ```powershell
     irm https://claude.ai/install.ps1 | iex
     ```
   - VS Code: install the "Claude Code" extension from the Marketplace
     (the project was edited with this extension active).
   - Sign in with the same Anthropic account that has access to your
     plan (Pro / Team / Enterprise) so the skills below resolve.

2. **Skills** referenced during this build (install via the
   `/skill install <name>` command inside Claude Code, or accept the
   prompt the first time the skill is needed):
   - `update-config` — manage `~/.claude/settings.json`, hooks, env vars
   - `keybindings-help` — keyboard shortcut customisation
   - `simplify` — review changed code for reuse / quality
   - `fewer-permission-prompts` — auto-allowlist common read-only Bash
   - `loop` — run a prompt or slash command on an interval
   - `schedule` — cron-style scheduled remote agents
   - `claude-api` — for any Claude/Anthropic SDK work in `server/`
   - `api-design-principles`, `auth-implementation-patterns`
   - `brainstorming`, `writing-plans`, `executing-plans`,
     `subagent-driven-development`, `dispatching-parallel-agents`
   - `frontend-design`, `ui-ux-pro-max`, `impeccable`,
     `responsive-design`, `web-design-guidelines`,
     `tailwind-design-system`, `design-system-patterns`,
     `ckm-design`, `ckm-banner-design`, `ckm-brand`,
     `ckm-design-system`, `ckm-slides`, `ckm-ui-styling`,
     `design-for-ai`
   - `vercel-cli-with-tokens`, `deploy-to-vercel`,
     `vercel-composition-patterns`, `vercel-react-best-practices`,
     `vercel-react-native-skills`, `vercel-react-view-transitions`
   - `nextjs-app-router-patterns`, `nodejs-backend-patterns`,
     `fastapi-templates`, `react-state-management`
   - `database-migration`, `postgresql-table-design`,
     `prisma-database-setup`, `neon-postgres`,
     `sql-optimization-patterns`
   - `embedding-strategies`, `hybrid-search-implementation`,
     `vector-index-tuning`, `rag-implementation`,
     `langchain-architecture`, `llm-evaluation`,
     `prompt-engineering-patterns`, `ml-pipeline-workflow`
   - `microservices-patterns`
   - `systematic-debugging`, `test-driven-development`,
     `verification-before-completion`, `receiving-code-review`,
     `requesting-code-review`, `using-git-worktrees`,
     `finishing-a-development-branch`, `using-superpowers`,
     `writing-skills`
   - Built-in slash commands relied on: `/init`, `/review`,
     `/security-review`, `/ultrareview`, `/loop`, `/fast`

3. **API access for Claude features in this app** (separate from the
   editor login — these power runtime AI features, not the build):
   - **Gemini API key** (chatbot proxy) — see §C5 env block.
   - **Optional Anthropic API key** if you swap the chatbot to Claude
     (`server/Routes/chatbotRoutes.js` notes how).

4. **Verify the install** on a new machine:
   ```bash
   claude --version
   claude /skill list           # should print every skill above
   ```
   If a skill isn't listed, run `claude /skill install <name>`.

5. **Repo-level config that Claude reads**:
   - `~/.claude/settings.json` (per-user) — your global settings.
   - This repo currently has no `.claude/settings.json` at the project
     root. If you want project-scoped permissions or hooks, create
     `.claude/settings.json` and commit it.

Without these skills installed, the agent can still build and run the
app, but advanced workflows (multi-agent reviews, planning mode, Vercel
one-shot deploys, Gemini API caching, etc.) will fall back to plain
text and you'll need to drive them manually.

### D1. AAR `flutter_local_notifications` desugaring error
Already configured (`isCoreLibraryDesugaringEnabled = true`,
`desugar_jdk_libs:2.1.4`). The error you saw was a stale Gradle cache.
Fix:
```
flutter clean
flutter pub get
flutter run
```
If it persists, delete `%USERPROFILE%\.gradle\caches` and try again.

### D2. Same-drive symlink warning
Move the project from `G:\` to `C:\` (under the Flutter SDK drive) to
remove the `ERROR_INVALID_FUNCTION` symlink warning during `pub get`.
Builds work either way.

---

## E. Decisions confirmed (locked in)

1. **Sign translator backend → BOTH** with a profile toggle "Use cloud
   sign translation" (cloud OFF by default).
2. **SOS cancel → big cancel button only** (no shake gesture).
3. **Profile photo → dedicated skippable step** after OTP.
4. **Brand social handles → placeholders** in
   `lib/src/core/config/ishara_brand.dart`.

---

## F. Suggested execution order

1. **A1** translator desync (headline feature blocker)
2. **A2** SOS button wiring (safety-critical)
3. **A6** accessibility redo (large self-contained block)
4. **A4** i18n sweep (mechanical)
5. **A5** flip social links to brand-only (small)
6. **B1** profile-photo skip step (small)
7. **A3** sign model accuracy / cloud toggle (depends on server deploy)
8. **C1-C5** as assets/keys land
9. **C6-C12** before public launch

---

## G. Files touched (index)

**Modify:**
- `lib/src/features/translator/data/sign_language_service.dart` (A1)
- `lib/src/features/translator/presentation/translator_controller.dart` (A1, A3)
- `lib/src/features/safety/presentation/safety_screen.dart` (A2)
- `lib/src/features/safety/presentation/safety_controller.dart` (A2)
- `lib/src/core/settings/translations.dart` (A4)
- `lib/main.dart` (A4 RTL wiring)
- `lib/src/core/settings/accessibility_settings.dart` (A6)
- `lib/src/core/theme/ishara_theme.dart` (A6 colour tokens)
- `lib/src/features/auth/presentation/otp_screen.dart` (B1)
- `lib/src/features/profile/presentation/profile_screen.dart` (A5, B1)
- `lib/src/features/profile/presentation/social_links_screen.dart` (A5 rewrite)
- Every new screen needing i18n strings (A4)

**New:**
- `lib/src/features/translator/data/remote_sign_service.dart` (A3)
- `lib/src/core/services/haptics_service.dart` (A6)
- `lib/src/core/widgets/motor_aware.dart` (A6)
- `lib/src/core/widgets/auto_tts_scope.dart` (A6)
- `lib/src/core/config/ishara_brand.dart` (A5)
- `lib/src/features/auth/presentation/profile_photo_setup_screen.dart` (B1)
- `lib/src/features/profile/presentation/accessibility_preview_screen.dart` (A6)

**Server (optional):**
- `server/Routes/brandRoutes.js` (A5 cloud variant)
- `server/models/User.js` minor (A5: drop user `socialLinks`)

**Assets:**
- `assets/fonts/OpenDyslexic-*.ttf`, `Tajawal-*.ttf`
- `assets/videos/signs/*.mp4`
- `assets/models/currency_egp.tflite`, `mobilenet_v3_large.tflite`,
  `imagenet_labels.txt`

---

## H. What I need from you

1. **Real Ishara social handles** when you have them (paste into
   `ishara_brand.dart` — placeholders are in there now).
2. **Sign-language clip MP4s** (or approved sources to download).
3. **API keys** (Twilio, Telegram Bot, Gemini) and a server host pick.
4. **Sign translator cloud server URL** once deployed (for the cloud
   toggle).

Everything else in §A, §B, §C (apart from the above provider-supplied
items) I'll execute end-to-end.

---

## I. Summary status table

| Feature | Status | Blocker |
|---|---|---|
| Auth + MongoDB | ✅ done | Server deploy + env keys |
| Sign Translator (on-device) | ❌ broken | A1 + A3 |
| Sign Translator (cloud) | 🆕 new | A3 path |
| Text → Sign | ⚠️ partial | C1 video clips |
| Vision OCR | ✅ done | — |
| Vision Currency total | ⚠️ heuristic | C2 EGP TFLite |
| Vision fine-grained objects | ⚠️ partial | C3 ImageNet TFLite |
| In-app SOS button | ❌ broken | A2 |
| Multi-contact dispatch (server) | ✅ done | C4 keys |
| Hardware glasses SOS | ✅ wired | C6 background service |
| Learning Quiz | ✅ done (3/4) | C1 + C7 |
| Shop | ✅ done | Run seed script |
| Chatbot | ✅ done | C4 Gemini key |
| Brand social links | ❌ wrong direction | A5 |
| Sharing buttons | ⚠️ partial | C8 rollout |
| Accessibility settings | ⚠️ partial | A6 full redo |
| i18n / RTL | ❌ partial | A4 |
| Profile photo step | 🆕 new | B1 |
| Theme polish | ⚠️ partial | C9 |
| Real payment | ⚠️ none | C11 |
| Social login | ⚠️ none | C12 |
