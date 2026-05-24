# Redmi Note 10S (rosemary) Custom ROM Features Roadmap

A pragmatic feature plan for a custom LineageOS-based ROM targeting `rosemary` (and siblings `maltose`, `secret`, `rosemaryp`, `secretr`) — MediaTek MT6785 (Helio G95), Linux 4.19 non-GKI kernel, 4 / 6 GB RAM, 6.43" AMOLED 1080p60, in-display fingerprint (UDFPS), 5000 mAh battery, IR blaster, stereo speakers, NO NFC on the `maltose` (India) variant.

This roadmap is grounded in:
- **crDroid 16.x** feature set (the de-facto reference for "what a feature-rich AOSP ROM ships in 2026")
- **HyperOS 2.x** features that the community is actively porting to AOSP (Gallery+OCR, Scanner, Sound Recorder, etc.)
- What **4PDA**, **XDA**, and **xiaomi.eu** users actually praise on rosemary today (EvolutionX, AxionOS, LineageOS 22.2 / 23.2, Project Matrixx)
- What is **realistic** on a 12 nm Helio G95 — there is NO Pixel-class NPU and NO GKI kernel, so Gemini-Nano-style on-device LLMs and Gemini-tier camera features are off the table; ML Kit-tier on-device inference (text recognition / image labelling / face detection) is viable

Each item carries: **Category**, **Implementation surface**, **rosemary-specific notes**, and a **Priority** rating:

- 🟢 **Must-have** — stable, well-trodden, low risk, expected by users
- 🟡 **Should-have** — high value but takes care to implement / test
- 🔴 **Stretch** — feasible but expensive in dev time, hardware-marginal, or polish-heavy

---

## Phase 1 — UI Foundation (the "feature-rich AOSP" baseline)

Everything in this phase is shipped by crDroid, EvolutionX, RisingOS, Project Matrixx. Without these the ROM looks like vanilla AOSP and won't attract users coming from MIUI / HyperOS.

1. **Status Bar Customization** 🟢
    - Clock position (left/center/right), seconds, AM/PM toggle, custom date formats
    - Battery icon styles (portrait/landscape/circle/text/hidden) + percentage placement
    - Network traffic indicator (up/down arrows, units, threshold to auto-hide)
    - Hide-icons list (VoLTE, VoWiFi, HD, roaming, Bluetooth battery)
    - Privacy chips for mic/camera/location/screen-share (AOSP 12+ default, expose toggles)
    - **Surface:** `frameworks/base/packages/SystemUI`, settings in `LineageParts`

2. **Quick Settings Panel** 🟢
    - Tile layout (columns × rows for portrait/landscape independently)
    - Drag-to-reorder + add/remove custom tiles (Caffeine, Sync, Screen Record, ADB-over-Network, DataSwitch, AOD, Heads-up, Sound Mode, Reading Mode, Compass, Reboot, etc.)
    - QS header image (image or **GIF** — crDroid 12.9 added GIF support)
    - Brightness slider position (top/bottom), haptics, auto-brightness toggle button
    - Footer data-usage label
    - **Surface:** `SystemUI` QSTileHost, tile providers; many tiles already exist in lineage-sdk

3. **Advanced Power Menu** 🟢
    - Restart → System / Recovery / Bootloader / Fastbootd / SystemUI hot-reboot
    - Screenshot, Lockdown, Users, Device Controls, On-The-Go (USB-OTG hotplug)
    - Secure power-menu access on lockscreen toggle
    - **Surface:** `SystemUI` GlobalActions, `PowerManager`

4. **Material You / Monet Theming** 🟢
    - Accent color sources: wallpaper / preset / custom hex
    - Monet style picker (TonalSpot, Vibrant, Expressive, Rainbow, FruitSalad, etc. — Android 14+ Engine)
    - Luminance / chroma sliders
    - Icon shapes (squircle, teardrop, hexagon, pebble, sammy, …)
    - System font picker (Roboto, Google Sans, Aclonica, manrope, etc.)
    - **Surface:** `frameworks/base` ThemeOverlayController, RROs in `device/lineage/overlay`
    - **Note:** Android 15+ moves SystemUI to Compose / Scene Framework — overlay strategy must account for that (see `LineageOS_UI_Customization_SKILL.md` §Compose)

5. **Customizable Gestures** 🟢
    - Status bar: tap-to-sleep, brightness slide, quick pulldown (right/left/always)
    - Three-finger swipe → screenshot / partial screenshot / split-screen
    - Volume buttons → wake / answer / media skip when screen off / rotate cursor (keyboard mode)
    - Power button: long-press → assistant / torch; double-tap → camera
    - **Surface:** `SystemUI`, `InputManagerService`, `PhoneWindowManager`

6. **Partial & Scrolling Screenshots** 🟢
    - AOSP 12+ scroll-capture API already wired — expose, polish, add long-screenshot timeout
    - Markup tool (crop / blur / text / arrow)
    - Optional screenshot sound toggle
    - **Surface:** `SystemUI` ScreenshotController

7. **Volume Panel** 🟢
    - Position: left / right
    - Expanded panel (all streams at once) toggle
    - Haptics + timeout sliders
    - **Surface:** `SystemUI` VolumeDialog

8. **Pixel-style Launcher (Trebuchet+)** 🟢
    - At-a-glance, hotseat search bar, taskbar (large-screen mode), drawer search, themed icons
    - **Surface:** `packages/apps/Trebuchet` — LineageOS' Launcher3 fork

---

## Phase 2 — Lockscreen & AMOLED Display (rosemary's AMOLED is an asset)

rosemary has a real AMOLED panel — features that are merely "nice" on LCD become "core" here.

1. **Always-On Display (AOD)** 🟢
    - Clock face picker (Pixel-style, MIUI-style, text-only, analog)
    - Scheduling (always / on-demand / timed window / charging-only)
    - Tilt-to-wake, pickup-to-wake, hand-wave-to-wake (sensors-aware), pocket-detection
    - Notification icons + first-line preview on AOD
    - **Surface:** `SystemUI` DozeService, `frameworks/base` AmbientDisplayConfiguration
    - **rosemary note:** AMOLED → near-zero AOD cost; this is one of the highest-ROI features on this device.

2. **Lockscreen Customization** 🟢
    - Clock font + size + position
    - Weather widget (LineageWeatherProvider already exists)
    - Media cover art as wallpaper, pulse/visualizer
    - Custom UDFPS icons + screen-off UDFPS (sensor permitting), fingerprint vibration profile
    - Battery info bar, charging info text
    - **Surface:** `SystemUI` KeyguardClock*, KeyguardIndication, UDFPS controller

3. **Edge Lighting / Pulse / Punch-hole Light** 🟡
    - Animated edge light on incoming notifications/calls
    - Punch-hole notification ring (front camera cutout halo — same idea as Energy Ring apps but native)
    - **Surface:** `SystemUI` overlay window; battery cost is real, ship as opt-in

4. **Charging & Screen-off Animations** 🟢
    - Custom charging animation themes
    - Screen-off CRT-style animation (Lineage already ships this)
    - **Surface:** `SystemUI`, `frameworks/base` ScreenOffAnimation

5. **Smart Pixels / Burn-in Mitigation** 🟡
    - Periodically shifts UI 1–2 px to mitigate AMOLED burn-in for users who run AOD heavy
    - **Surface:** `SystemUI` overlay + pixel-shift overlay
    - **Note:** Optional; AMOLED panels at 1080p are fairly burn-resistant but worth offering.

---

## Phase 3 — Privacy, Security & Integrity

This is the area that has changed the most in 2025–2026. The community has moved past Magisk-only Play-Integrity hacks.

1. **Per-App Permission Hardening** 🟢
    - Per-app sensor blocking (mic / camera / location / accelerometer / gyro) — crDroid ships this
    - Per-app network access (Wi-Fi / cellular / VPN-only) — uses AOSP `NetworkPolicyManager`
    - Per-app battery / background restriction (already AOSP; expose more granular)
    - **Surface:** `frameworks/base` AppOps, `SensorPrivacyService`, `NetworkPolicyManagerService`

2. **Privacy Dashboard Plus** 🟡
    - Extend AOSP Privacy Dashboard with **clipboard reads** and **sensor reads** timeline
    - Permission usage notifications (opt-in toast when app accesses sensitive permission)
    - **Surface:** `frameworks/base` PermissionUsage logging

3. **Play Integrity Spoof (with TrickyStore-style keybox)** 🟡
    - Built-in PI/SafetyNet spoof so banking apps work without Magisk
    - **VBMeta autofix** + keybox attestation override (crDroid 12.9+ approach)
    - **Surface:** PixelPropsUtils / `frameworks/base` Build.java overlay, integration with a keystore stub
    - **rosemary caveat:** rosemary's bootloader is unlockable but lacks hardware key attestation; spoof works at the software layer only — banking apps that require StrongBox attestation will still fail (true on all unlocked devices).

4. **App Locker** 🟢
    - PIN / pattern / biometric gate on per-app basis
    - Hidden / secured folders
    - **Surface:** `ActivityManagerService` hook, `LauncherApps`, `KeyguardManager`
    - **Note:** Android 15 added native app archive — coordinate so App Locker doesn't fight with it.

5. **Microphone & Camera Hardware Toggles** 🟢
    - Global mic-off / cam-off QS tiles wired to `SensorPrivacyManager` (AOSP 12+ API)
    - **Surface:** `SystemUI` sensor-privacy tiles

6. **Hosts-based Ad-block / DNS-over-HTTPS** 🟡
    - System-wide hosts file rule loader, plus settings UI for Private DNS (already AOSP) with curated provider list (Cloudflare 1.1.1.1 family, Quad9, NextDNS, AdGuard)
    - **Surface:** init.rc hosts overlay, Settings → Network → Private DNS

---

## Phase 4 — Performance & Gaming (Helio G95 specific)

The G95 is a 12 nm Cortex-A76+A55 chip with Mali-G76 MC4. Sustained performance is thermal-bound. Features here should *manage* that ceiling, not pretend the chip is something it isn't.

1. **Game Space / Game Mode** 🟢
    - Per-app game profile: lock to performance governor, **FPS unlock** (crDroid ships this), block notifications, gesture-lock corners, screenshot/screen-record overlay, network priority
    - **Surface:** `SystemUI` GameSpace activity, `PowerManager` boost hint, `WindowManager` immersive
    - **rosemary note:** Mali-G76 MC4 ceiling is 900 MHz — sustained boost will throttle within 5–10 min on heavy 3D titles. Expose **CPU large-core governor** override per-game so the user can pick `performance` vs `schedutil`.

2. **Adaptive Refresh Rate / Dynamic Resolution** 🟡 → 🔴
    - rosemary panel is **60 Hz only** so true LFPS isn't a thing here. But:
    - **Dynamic resolution** (drop to 720p in heavy games) is a real win on G95 — render-budget cut of ~40%
    - Wire to `SurfaceFlinger` resolution override via `wm size` / `wm density` per-app
    - **Surface:** `SurfaceFlinger`, `DisplayManager`, per-app override in Game Space

3. **Thermal Profile Picker** 🟡
    - Three-stop slider: `cool` (lower CPU/GPU ceilings, sustained), `balanced` (stock), `performance` (raise ceilings, accept thermal throttle later)
    - Backed by stock MTK thermal-config JSON swap in `vendor/etc/thermal-engine*.conf`
    - **Surface:** Settings tile, init script to swap thermal config and restart `thermal-engine`
    - **rosemary caveat:** MTK thermal-engine is closed-source; we're just swapping its config files. Test carefully — wrong config + Helio G95 = uncomfortably hot device.

4. **Memory / RAM Management** 🟢
    - Expose AOSP per-app standby buckets, allow user to whitelist "never-freeze" apps
    - LMK tuning profile picker (Aggressive / Balanced / Gaming-friendly)
    - **rosemary note:** 4 GB variants are RAM-starved on Android 14+; ship Balanced default and 720p fallback for app drawer / wallpaper.

5. **Adaptive Charging** 🟢
    - Charge to 80 % then hold until alarm-based wake-up time (battery-longevity feature, AOSP 14+ has hooks)
    - **Surface:** `BatteryStatsService`, alarm-aware charge limiter

6. **Battery Charge Limit (long-life mode)** 🟢
    - Hard cap at user-chosen percent (60 / 70 / 80 / 90) — write to `/sys/class/power_supply/battery/input_suspend` style sysfs
    - **Surface:** kernel sysfs node + Settings toggle
    - **rosemary kernel note:** MT6785 vendor kernel needs a patch to expose a clean charge-control sysfs node — check `kernel/xiaomi/mt6785` to see what nodes already exist before adding your own.

---

## Phase 5 — Modern Apps & HyperOS Ports (where the OCR Gallery lives)

This is the phase that turns a "yet another AOSP build" into something users prefer over MIUI. All of these are app-level — they don't require deep frameworks/base patching, which lowers risk.

1. **Gallery with OCR** 🟡  ← *the feature you flagged as a powerful tool, and you're right*
    - **Approach A (recommended):** ship `SimpleGallery` (FOSS, GPL, already in F-Droid) + a small OCR plugin built on **Google ML Kit Text Recognition v2** (on-device, free, Latin + CJK / Devanagari / Arabic models, ~3 MB each, runs fine on G95 via NNAPI)
    - **Approach B:** port **HyperOS Gallery** (Mi Gallery + Editor + Scanner) — these have been successfully ported to AOSP per `LLionsMods` / Telegram hyperosroms community. Pros: polished, AI background eraser, magic eraser, sky replace. Cons: closed-source, MIUI-specific framework hooks that need stubs.
    - **Approach C (cleanest, FOSS):** port **Ente Photos**' OCR plugin — Flutter + ONNX Runtime Mobile, fully open, runs locally, handles rotated docs + multi-language receipts.
    - **rosemary feasibility:** the G95 APU is a 1st-gen MediaTek APU. It's not Tensor-class but it handily runs ML Kit text recognition (~100 ms per page) and image labelling.
    - **What "OCR in Gallery" buys the user:** searchable photo library (search "INVOICE" → finds all photos containing that word), copy-text-from-screenshot, translate-from-image, business-card capture.

2. **System Scanner App (QR / OCR / Document / Translate)** 🟡
    - HyperOS Scanner is the gold standard here — port it (the community has) or replace with FOSS:
        - **OpenScanLibrary** (BSD, document detection, perspective correction)
        - **ML Kit Text Recognition v2** for OCR (free, on-device)
        - **ZXing-cpp** for QR / barcode
        - **MLKit Translate** for offline translation packs
    - Features: ID card scan with redaction, table/PPT/PDF mode, text-to-clipboard, translate
    - **Surface:** standalone app, optional bundled in `packages/apps/`

3. **Modern Sound Recorder** 🟢
    - HyperOS Recorder port is popular; alternative is **Audio Recorder** (FOSS) with **on-device transcription** via Whisper.cpp (tiny model, ~75 MB, runs on G95 CPU at ~0.4× realtime — usable for short clips)
    - Features: lockscreen widget, earpiece playback, mark moments during recording, transcribe-to-text
    - **Surface:** standalone app

4. **Files / File Manager** 🟢
    - Replace stock with **Material Files** (FOSS, Material You) or port HyperOS File Manager
    - Built-in archive (zip / 7z / tar / xz), SFTP / SMB / WebDAV, root mode (off by default)

5. **Weather App with widgets** 🟢
    - **Breezy Weather** (FOSS, MIT) is the community choice — supports 30+ providers, has Material You widgets matching HyperOS aesthetic
    - Wire it into AOSP LockscreenWeatherProvider

6. **Notes app with sync** 🟢
    - **Markor** (FOSS) or **Quillpad** (FOSS, Material You)

7. **PDF reader, Calculator, Clock** 🟢
    - Replace AOSP defaults with **MuPDF mini**, **OpenCalc**, **Simple Clock** — collectively saves ~30 MB and looks consistent with the Monet theme.

---

## Phase 6 — On-device Intelligence (G95-realistic AI)

Everything here uses **ML Kit / NNAPI / TFLite-LiteRT** — not Gemini Nano (Pixel 8+ NPU only) and not cloud APIs. Stays within the chip's real capability.

1. **Smart Replies in Notifications** 🟡
    - AOSP's built-in `TextClassifier` API already does this — most ROMs just don't wire it up. Enable the system-side ML Kit smart-reply model on outgoing reply UI.
    - **rosemary feasibility:** Very. Smart-reply model is ~5 MB, runs in <50 ms on G95.
    - **Surface:** `frameworks/base/core/java/android/service/notification` + `TextClassificationManager`

2. **Live Caption (system-wide audio → text)** 🟡
    - AOSP 11+ has the Live Caption framework; the model isn't shipped by AOSP (it's a Google blob).
    - **FOSS alternative:** Mozilla Common Voice models or Whisper-tiny, wired into AccessibilityService.
    - **rosemary feasibility:** Whisper-tiny is heavy (~75 MB, ~0.4× realtime CPU) — feasible for prerecorded media, marginal for live calls. Ship as opt-in beta.

3. **Image Labelling & Smart Albums in Gallery** 🟡
    - Use ML Kit Image Labelling to auto-group photos into Pets / Food / Documents / Receipts / Screenshots / People (face clustering uses MLKit Face Detection)
    - Pairs with the Gallery OCR work in Phase 5.

4. **AI Wallpaper Depth Effect (HyperOS-style)** 🔴
    - HyperOS 2 ships frame-by-frame depth segmentation for cinematic lockscreen effect. Doable with MediaPipe Selfie Segmentation model (~2 MB, runs on G95) — but the polish to make it not-janky on a 60 Hz panel is real engineering work. Stretch goal.

5. **Adaptive Battery (real, not marketing)** 🟢
    - AOSP already ships AdaptiveBattery (an on-device ML model that learns app-launch patterns and slots apps into standby buckets). Most custom ROMs leave it half-wired.
    - **Action:** ensure `device_config` flags for adaptive_battery are enabled at boot, surface a Settings page that shows the model's predictions, allow user override.
    - **Why this replaces the old roadmap's "AI Battery Management":** that was vaporware; this is a real Google-trained model already in AOSP, just under-exposed.

6. **What's NOT feasible — be honest with users**
    - ❌ Gemini Nano on-device LLM (requires Tensor NPU; Pixel 8+ only)
    - ❌ Real-time AI video super-resolution at 4K (G95 marketing claims this but only at 360p→720p upscale, with massive thermal cost)
    - ❌ AI scam-call detection that runs entirely on-device on G95 (model size + audio pipeline > G95 sustained budget)

---

## Phase 7 — Camera (this is hard, be honest)

The current rosemary LineageOS camera stack is the device's weakest link — every XDA/4PDA review points to this. The roadmap shouldn't pretend AI fixes it; it's a Camera HAL & blob problem.

1. **Camera HAL fixes** 🟢
    - Use TheMuppets blob set + the device-tree maintainer's Camera HAL patches (`device/xiaomi/rosemary`)
    - Ensure Camera2 API levels: front cam should report **FULL** (currently reports LIMITED on some builds)
    - **Surface:** device tree, HAL blob version pinning

2. **GCam port compatibility** 🟢
    - This is *not* a ROM feature per se — it's making sure the Camera HAL and Camera2 props are correct enough for community GCam ports (BSG, Greatness, Wichaya) to install and use HDR+ / Night Sight.
    - Document the recommended GCam config XML in README

3. **OpenCamera bundled** 🟡
    - Ship **OpenCamera** (FOSS) as a secondary camera app — many users prefer it to the stock app and it doesn't need GCam blob hacks.

4. **What's NOT in scope**
    - ❌ Building "our own AI Night Mode" — implementing Google's HDR+ pipeline from scratch is years of work and requires sensor RAW characterization that isn't public for rosemary.

---

## Phase 8 — Power-user / Advanced

1. **Native Magisk / KernelSU compatibility documentation** 🟢
    - Ship VBMeta + boot.img variants that are known-good for Magisk Delta and KernelSU; document patching steps in `README.md` post-flash section
    - **rosemary kernel note:** MT6785 is non-GKI; KernelSU-Next requires the kernel-side patches in the `device/xiaomi/mt6785-common` tree — verify they're applied.

2. **Call Recording** 🟡 — *jurisdiction-dependent*
    - LineageOS already supports this where legal (India: legal with disclosure; EU: mostly illegal without consent)
    - **Surface:** `packages/apps/Dialer` + recording HAL
    - Default-off, with country-aware notice

3. **Screen Recorder with internal audio** 🟢
    - AOSP 11+ supports this; expose it as a proper QS tile with bitrate / framerate / mic-mux options
    - **Surface:** `SystemUI` ScreenRecord

4. **App Cloner / Parallel Apps** 🟡
    - Use AOSP work-profile API to clone WhatsApp / Telegram / messengers per user-account
    - **Surface:** `Settings` → Multiple users → "Create cloned app"

5. **Network Access Control (Per-app firewall)** 🟡
    - Use AOSP `NetworkPolicyManager` (already kernel-side; iptables is unnecessary on Android 12+)
    - **Surface:** Settings UI

6. **Backup app (Seedvault)** 🟢
    - GrapheneOS' Seedvault is FOSS, ships with system-key encryption — easy add, big value
    - **Surface:** `packages/apps/Seedvault`

7. **IR Blaster preservation** 🟢
    - rosemary has an IR blaster; the stock Mi Remote APK is the user-favorite. Keep it working by preserving the IR HAL blob and including a FOSS alt (e.g. **IR Remote** by F-Droid) as fallback.

---

## What was removed / restructured from the previous draft

- **"Smart Battery Management (AI-Driven)"** — replaced with **Adaptive Battery (real, already in AOSP)** in Phase 6. The old framing was vaporware; the new one ships a real Google ML model that's just under-wired in most ROMs.
- **"On-Device Smart Replies (Gemini Nano)"** — kept the *Smart Replies* idea but stripped Gemini Nano. Gemini Nano requires Tensor NPU and isn't going to run on the G95 APU. ML Kit smart-reply (~5 MB) is what's realistic.
- **"GCam Integration"** — recharacterized as a Camera HAL + Camera2 prop concern in Phase 7, not an AI feature. GCam is just an APK; making it *work* on rosemary is a HAL job.

## What's intentionally NOT on the roadmap

- Per-app screen refresh rate (rosemary is 60 Hz only)
- 5G mmWave features (modem doesn't have it)
- Wireless charging features (no Qi coil)
- NFC payments (maltose Indian variant has no NFC chip; including this would alienate the user base)
- Pixel-class on-device LLMs / Gemini Nano (no NPU, no Tensor; chip can't run the models in any usable latency budget)

---

## Suggested build order

1. **Phase 1** (UI baseline) + **Phase 7.1–7.2** (Camera HAL fixes) — without these the ROM is unusable as a daily driver
2. **Phase 2** (lockscreen/AOD) + **Phase 3.1, 3.4, 3.5** (privacy basics) — high user-visible value, low risk
3. **Phase 4** (gaming/perf) + **Phase 8.3, 8.6** (screen rec, Seedvault) — daily-driver polish
4. **Phase 5** (modern apps incl. Gallery+OCR) — the *differentiator* vs. plain LineageOS
5. **Phase 3.3** (Play Integrity / TrickyStore) + **Phase 6.1, 6.3, 6.5** (smart replies, image labelling, adaptive battery) — the "modern AI ROM" story
6. **Phase 2.3, 2.5, 6.4** (edge lighting, smart pixels, AI depth wallpaper) — the "wow, this is polished" stretch tier

---

## References (what shaped this roadmap)

- crDroid Android 16.x features list — [crdroidandroid/crdroid_features](https://github.com/crdroidandroid/crdroid_features/blob/16.0/README.mkdn)
- crDroid 12.9 / 12.10 release notes — [crdroid.net blog](https://crdroid.net/blog/2026-05-10-crDroid-12.10-is-here)
- LineageOS 22.2 for rosemary — [XDA thread](https://xdaforums.com/t/lineageos-22-2-android-15-for-xiaomi-redmi-note-10s-codename-rosemary-official.4758056/)
- AxionOS 2.0 for rosemary (A15+A16) — [XDA thread](https://xdaforums.com/t/updated-18-09-2025-rom-axionos-2-0-android-15-16-for-rosemary-redmi-note-10s.4735862/)
- Project Matrixx (crDroid-derived) — [projectmatrixx.org](https://www.projectmatrixx.org/changelog)
- HyperOS-to-AOSP ports (Gallery, Scanner with OCR, Recorder, etc.) — [LLionsMods Telegram](https://t.me/s/llionsmods/1116), [hyperosroms GitHub](https://github.com/hyperosroms)
- 4PDA rosemary unofficial firmware thread — [4pda.to/forum/showtopic=1035002](https://4pda.to/forum/index.php?showtopic=1035002)
- ML Kit Text Recognition v2 (on-device OCR) — [Google Developers](https://developers.google.com/ml-kit/vision/text-recognition/v2/android)
- Ente Photos OCR (ONNX-based, FOSS) — [ente.com/blog/ocr](https://ente.com/blog/ocr/)
- Helio G95 spec / APU capability — [MediaTek](https://www.mediatek.com/products/smartphones/mediatek-helio-g95)
- HyperOS 2 feature list (what users are asking ROM devs to port) — [TechWiser](https://techwiser.com/xiaomi-hyperos-2-features-and-release-schedule/), [Cashify](https://www.cashify.in/hyperos-2-0-eligible-devices-release-date-all-details-list)
- LineageOS UI customization deep-dive — [LineageOS_UI_Customization_SKILL.md](./LineageOS_UI_Customization_SKILL.md) (this repo)
- ROM debugging reference — [ROM_Debugging_SKILL.md](./ROM_Debugging_SKILL.md) (this repo)
