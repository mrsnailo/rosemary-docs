# rosemary ROM — Backlog

Active tracking for ROM feature work. The "what to build" reference is [ROM_FEATURES_ROADMAP.md](./ROM_FEATURES_ROADMAP.md); this file is "what we're working on right now and what's next."

**Status legend:** `planned` → `in-progress` → `blocked` / `done` / `dropped`. Mark `done` only after the change has been built, flashed to `rosemary`, and smoke-tested on the device.

**Workflow per feature:**
1. Move row to `in-progress` and write the detailed section below the table.
2. Implement against `~/android/lineage/` source tree, commit per meaningful step.
3. Build (`brunch rosemary`), flash, smoke test → only then mark `done`.

---

## Table

| ID  | Feature                                    | Phase | Status      | Next action                                | Notes |
|-----|--------------------------------------------|-------|-------------|--------------------------------------------|-------|
| F01 | Gallery with OCR                           | 5     | in-progress | Pick app base (SimpleGallery / Ente / HOS) | The "powerful tool" — first active item. |
| F02 | Status bar customization                   | 1     | planned     | Clone Lineage `SystemUI` baseline          | Foundation. Many sub-options. |
| F03 | Quick Settings panel customization         | 1     | planned     | Tile-host audit                            | Includes GIF QS header. |
| F04 | Advanced power menu                        | 1     | planned     | GlobalActions audit                        | Recovery / Fastbootd / hot-reboot. |
| F05 | Material You / Monet theming               | 1     | planned     | ThemeOverlayController audit               | Style picker + RROs. |
| F06 | Customizable gestures                      | 1     | planned     | InputManagerService audit                  | Three-finger, double-tap, etc. |
| F07 | Partial & scrolling screenshots            | 1     | planned     | ScreenshotController audit                 | Polish AOSP 12+ default. |
| F08 | Volume panel (position, expanded, haptic)  | 1     | planned     | VolumeDialog audit                         |       |
| F09 | Pixel-style launcher (Trebuchet+)          | 1     | planned     | Lineage Trebuchet baseline                 | At-a-glance, themed icons. |
| F10 | Always-On Display (AOD)                    | 2     | planned     | DozeService audit                          | AMOLED win, high ROI. |
| F11 | Lockscreen customization                   | 2     | planned     | KeyguardClock audit                        | UDFPS icons, weather. |
| F12 | Edge lighting + punch-hole notification    | 2     | planned     | Overlay-window strategy                    | Opt-in (battery). |
| F13 | Charging & screen-off animations           | 2     | planned     | ScreenOffAnimation audit                   |       |
| F14 | Smart pixels / burn-in mitigation          | 2     | planned     | Overlay shifter                            | Stretch. |
| F15 | Per-app sensor blocking                    | 3     | planned     | SensorPrivacyService audit                 | Mic/cam/loc/gyro per-app. |
| F16 | Privacy dashboard plus                     | 3     | planned     | PermissionUsage logging                    | Clipboard + sensor timeline. |
| F17 | Play Integrity spoof + TrickyStore         | 3     | planned     | PixelPropsUtils audit                      | Banking-app compat. |
| F18 | App locker                                 | 3     | planned     | ActivityManagerService hook                | A15 archive coexistence. |
| F19 | Hardware mic/cam toggles                   | 3     | planned     | Sensor-privacy QS tiles                    |       |
| F20 | Hosts ad-block + DoH presets               | 3     | planned     | Private DNS provider list                  |       |
| F21 | Game Space / Game Mode                     | 4     | planned     | SystemUI GameSpace activity                | FPS unlock + governor pin. |
| F22 | Dynamic resolution per app                 | 4     | planned     | SurfaceFlinger override                    | 720p drop for heavy games. |
| F23 | Thermal profile picker                     | 4     | planned     | MTK thermal-engine config swap             | Cool / balanced / perf. |
| F24 | Memory / LMK tuning profile                | 4     | planned     | Per-app standby buckets UI                 |       |
| F25 | Adaptive charging (alarm-aware)            | 4     | planned     | BatteryStatsService hook                   |       |
| F26 | Battery charge limit                       | 4     | planned     | Kernel sysfs audit                         | Needs MT6785 kernel patch. |
| F27 | System Scanner (QR/OCR/translate)          | 5     | planned     | Reuse F01 OCR pipeline                     | After F01. |
| F28 | Sound recorder w/ Whisper transcription    | 5     | planned     | App scaffold                               |       |
| F29 | File manager (Material Files / HOS port)   | 5     | planned     | Pick base                                  |       |
| F30 | Weather (Breezy Weather)                   | 5     | planned     | Wire into LockscreenWeatherProvider        |       |
| F31 | Notes app (Markor / Quillpad)              | 5     | planned     | Pick base                                  |       |
| F32 | PDF / Calculator / Clock replacements      | 5     | planned     | MuPDF mini, OpenCalc, Simple Clock         |       |
| F33 | Smart Replies in notifications             | 6     | planned     | TextClassifier wiring                      | ML Kit (NOT Gemini Nano). |
| F34 | Live Caption (Whisper-tiny)                | 6     | planned     | AccessibilityService                       | Opt-in beta. |
| F35 | Image labelling + smart albums             | 6     | planned     | After F01                                  |       |
| F36 | AI depth wallpaper                         | 6     | planned     | MediaPipe selfie segmentation              | Stretch. |
| F37 | Adaptive Battery (expose existing)         | 6     | planned     | device_config flags                        | Already in AOSP, just wire. |
| F38 | Camera HAL fixes                           | 7     | planned     | Device-tree maintainer patches             | Camera2 FULL on front cam. |
| F39 | GCam compatibility props                   | 7     | planned     | Document config XML                        |       |
| F40 | Bundle OpenCamera                          | 7     | planned     | packages/apps                              |       |
| F41 | Magisk / KernelSU docs                     | 8     | planned     | README post-flash section                  |       |
| F42 | Call recording (region-aware)              | 8     | planned     | Lineage dialer + recording HAL             |       |
| F43 | Screen recorder w/ internal audio          | 8     | planned     | ScreenRecord QS tile                       | AOSP 11+ supports. |
| F44 | App cloner / parallel apps                 | 8     | planned     | Work-profile API                           |       |
| F45 | Per-app firewall                           | 8     | planned     | NetworkPolicyManager                       |       |
| F46 | Seedvault backup                           | 8     | planned     | packages/apps/Seedvault                    |       |
| F47 | IR blaster preservation                    | 8     | planned     | Verify IR HAL blob                         | Plus FOSS fallback APK. |

---

## Active

### F01 — Gallery with OCR

**Goal:** Ship a gallery app on the rosemary ROM that runs on-device OCR over the user's photo library so they can search photos by text content and copy text out of any image.

**Steps:**
1. Pick app base — recommend **SimpleGallery Pro fork** (FOSS, GPL-3, actively maintained, Material You) + ML Kit Text Recognition v2 as the OCR engine. Decide vs HyperOS Gallery port (more polished but closed-blob) and Ente Photos (FOSS but Flutter, harder AOSP integration).
2. Vendor the chosen app source under `~/android/lineage/packages/apps/RosemaryGallery/` with an Android.bp that builds it as a privileged system app.
3. Wire ML Kit Text Recognition v2 (on-device, ~3 MB Latin model + opt-in Devanagari/CJK packs). OCR runs in a background `WorkManager` job on import; results stored in a small Room DB keyed by `MediaStore` content URI.
4. Add OCR-aware search to the gallery's existing search bar; add long-press → "Copy text" action on any image.
5. Add Settings entry: "Index new photos for text search" (default on, toggleable), language pack picker.
6. Smoke-build with `mka RosemaryGallery`, then full `brunch rosemary`, flash, test on device.

**Done-when:** Photo of a printed page or street sign, taken on rosemary, becomes searchable by text content within ~2 s of opening Gallery. Long-press "Copy text" works on a screenshot. No regression on plain photo browsing.

---
