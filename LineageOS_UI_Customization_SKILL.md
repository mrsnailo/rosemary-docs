# SKILL: LineageOS/AOSP UI Customization from Source

## Introduction

This document outlines techniques for customizing the User Interface (UI) within LineageOS or AOSP (Android Open Source Project) by modifying its source code. These methods range from simple resource overlays for theming to complex code patching for new features. Understanding these techniques is crucial for custom ROM developers, device maintainers, and anyone looking to deeply personalize their Android experience.

**Disclaimer**: Modifying the AOSP/LineageOS source requires a strong understanding of Android's architecture, Java/Kotlin programming, and the Android build system. Improper modifications can lead to device instability, boot loops, or security vulnerabilities. Always proceed with caution, back up your work, and test thoroughly.

## Prerequisites

Before attempting any UI customization from source, ensure you have the following:

1.  **AOSP/LineageOS Build Environment**: A fully set up environment capable of compiling Android from source. This typically includes:
    *   A Linux-based operating system (Ubuntu is common).
    *   Sufficient RAM (min 16GB, 64GB recommended) and disk space (min 300GB, 500GB+ recommended).
    *   Required build tools and libraries (OpenJDK, `repo`, `git`, `gperf`, `ccache`, etc.). Refer to `source.android.com/docs/setup/start/requirements` and the sibling `README.md` in this repo for a complete Ubuntu 24.04 install line.
2.  **Cloned AOSP/LineageOS Source Tree**: The complete source for the Android version you intend to modify. **Current rosemary target**: `lineage-23.2` (Android 16 QPR2). Older active branches: `lineage-22.2` (A15 QPR2), `lineage-21` (A14). Note the SystemUI changes documented in §"SystemUI Compose / Scene Framework" below only apply to lineage-22.2+.
3.  **Basic Android Development Knowledge**: Familiarity with Android app development (activities, services, layouts, resources) and Java/Kotlin. **Jetpack Compose** is required for any SystemUI Shade/QS/Lockscreen work on Android 15+.
4.  **`adb` (Android Debug Bridge)**: An essential command-line tool for interacting with your device for debugging, flashing, and logging.
5.  **Target Device**: A device for which you have compiled the AOSP/LineageOS source, ready for flashing modified images. Unlocked bootloader is a must.

## Foundational Concepts & Tools

### Core Components of Android UI

1.  **`SystemUI`**: This is a critical system application responsible for rendering and managing most of the user-facing system UI elements. It includes:
    *   Status Bar (icons, clock, notifications)
    *   Navigation Bar (back, home, recents buttons)
    *   Quick Settings Panel
    *   Notifications Shade
    *   Lock Screen
    *   Volume Panel
    *   Power Menu
    The source code for `SystemUI` is typically located in `packages/SystemUI/` within the AOSP tree.

2.  **`frameworks/base`**: This directory contains the vast majority of the core Android framework code, defining fundamental APIs, services, and UI components used by all applications and the SystemUI. Key areas for UI customization include:
    *   `core/res`: Contains the default Android resources (layouts, styles, colors, drawables, strings) that are available to all applications.
    *   `services`: Houses core system services, some of which manage UI interactions.

3.  **`packages/apps`**: This directory holds the source code for various pre-installed Android applications, such as:
    *   `Settings`: The system settings application, where custom features are often integrated.
    *   `Launcher3`: The default home screen application.
    *   Other core apps like `Phone`, `Contacts`, `Messaging`.
    Customization here involves modifying their specific resources or source code.

### Essential Tools & Concepts

1.  **`adb` (Android Debug Bridge)**: A versatile command-line tool for device communication, debugging, package management, and file transfer.
    *   [ADB Overview](https://developer.android.com/tools/adb)

2.  **Android's Resource System**: Android's UI relies heavily on XML-based resources for layouts, strings, dimensions, colors, drawables, and styles. This system enables theming and adaptation to various device configurations.

3.  **Android Build System (Soong & Make)**:
    *   **Soong (Android.bp)**: The primary build system for AOSP (since Android 7.0), using declarative `Android.bp` files.
    *   **Make (Android.mk)**: The older build system, still present for some legacy components.
    *   Understanding how to compile individual modules (`m <module_name>`) or the entire system (`make -jX`) is essential.
    *   [Build System Overview](https://source.android.com/docs/setup/build)
    *   [Building AOSP](https://source.android.com/docs/setup/build/building)

## Customization Techniques - Theming & Resources

### 1. Runtime Resource Overlays (RROs)

RROs are a powerful and relatively non-invasive way to theme or modify resource values of target packages without altering their original APKs. They are ideal for changing colors, drawables, and layouts.

*   **Concept**: An RRO is a separate APK that contains a mirrored `res/` structure of the target application. At runtime, the Android system applies these overlaid resources, effectively replacing the original ones.
*   **How to Create (General Steps)**:
    1.  **Create an Overlay Project**: Set up a new Android library project.
    2.  **`AndroidManifest.xml`**: Declare it as an overlay, targeting the package to be themed:
        ```xml
        <manifest ... package="com.yourpackage.overlay" >
            <overlay android:targetPackage="com.android.systemui"
                     android:priority="1"
                     android:isStatic="true" />
            ...
        </manifest>
        ```
        *   `android:targetPackage`: The package you want to overlay (e.g., `com.android.systemui`, `android` for framework resources).
        *   `android:priority`: (Optional) Specifies the order if multiple overlays target the same resource. Higher number means higher priority.
        *   `android:isStatic`: Set to `true` for overlays that are applied at boot (common for custom ROM theming).
    3.  **Mirror Resources**: Replicate the `res/` directory structure of the target package. For example, to change `system_accent_color` in `SystemUI`:
        ```
        your_overlay_project/
        └── res/
            └── values/
                └── colors.xml
        ```
        In `colors.xml`:
        ```xml
        <?xml version="1.0" encoding="utf-8"?>
        <resources>
            <color name="system_accent_color">#FF0000</color> <!-- Red accent -->
        </resources>
        ```
    4.  **Build**: Compile your overlay project into an APK.
*   **Applying and Managing**:
    *   **Static RROs**: These are typically placed in system partitions (e.g., `/system/product/overlay` or `/vendor/overlay`) during the ROM build process. Their activation might be controlled by flags in `overlay-config.xml` (Android 11+).
    *   **Dynamic RROs**: Can be enabled/disabled at runtime by applications using the `OverlayManagerService` (OMS), often seen with theme engines.
*   **Theming Capabilities**:
    *   **Colors**: Easily change system-wide colors, accent colors, background colors.
    *   **Drawables**: Replace icons, background images, shapes.
    *   **Layouts**: Modify layouts of target applications, though this needs careful matching of view IDs and structures.
    *   **Fonts**: Override font family declarations (requires careful setup).
*   **Key Resources for RROs**:
    *   [AOSP Documentation on RROs](https://source.android.com/docs/core/runtime/rros)
    *   [Troubleshooting RROs](https://source.android.com/docs/core/runtime/rro-troubleshoot)
    *   [Codelab: Create RROs with car-ui-lib components (Automotive, but principles apply)](https://source.android.com/docs/automotive/hmi/car_ui/codelab-rros)

#### Building an RRO with Soong (`runtime_resource_overlay`)

Avoid hand-rolled `Android.mk` for overlays. The modern path is a `runtime_resource_overlay` module in `Android.bp`:

```blueprint
runtime_resource_overlay {
    name: "RosemaryAccentOverlay",
    theme: "RosemaryAccent",
    sdk_version: "current",
    product_specific: true,
    // Critical: keep aapt2 from silently dropping resources
    // that don't match the target package's resource set.
    aaptflags: [
        "--no-resource-deduping",
        "--no-resource-removal",
    ],
}
```

Without those two `aaptflags`, aapt2 will trim "unused" resources during the overlay build and your overlay may install but silently fail to flip the color it was supposed to flip.

#### `overlay-config.xml` and `overlayable.xml` (Android 11+)

Since Android 11, `android:isStatic` and `android:priority` in the overlay's `AndroidManifest.xml` are **ignored** if the target partition has a `overlay-config.xml`. The newer model:

*   **`overlay-config.xml`** — placed at `<partition>/overlay/config/config.xml`, lists overlays in apply order. Partition precedence: `system < system_ext < product < vendor`. Each entry can set `enabled`, `mutable`, and per-overlay priority. This is now the authoritative source for "which overlays are on at boot."
*   **`overlayable.xml`** — placed inside the *target* package (e.g. `frameworks/base/core/res/res/values/overlayable.xml`) and declares which resources may be overlaid, gated by `<policy>` (signature / system / vendor / product / odm). An overlay attempting a resource outside its allowed policy is silently rejected at idmap-generation time, which is the most common reason a freshly-installed overlay does nothing.

#### Runtime overlay control with `cmd overlay` and `idmap2`

For iterating on an overlay without flashing or rebooting:

```bash
adb shell cmd overlay list                     # show every registered overlay and its state
adb shell cmd overlay enable  com.your.overlay # turn on
adb shell cmd overlay disable com.your.overlay # turn off
adb shell cmd overlay enable-exclusive --category com.your.overlay  # for category-grouped themes
adb shell cmd overlay set-priority com.your.overlay highest
adb shell cmd overlay dump                     # full state, useful when something isn't applying

# Why isn't my overlay binding to its target?
adb shell idmap2 dump --idmap-path /data/resource-cache/com.your.overlay@idmap
# Each line maps target-resource-id → overlay-resource-id. Missing entries mean the
# `overlayable.xml` policy rejected them.
```

#### Fabricated RROs (FRROs, Android 12+)

Traditional RROs are APKs you build, install, and toggle. **Fabricated RROs** let a system app (or root) mint an overlay at runtime, set integer/color/dimen/bool/string values, register it, and have it take effect — no APK build, no install, no reboot. This is how Pixel's Material You generates per-wallpaper themes on the fly.

```kotlin
// Requires android.permission.CHANGE_OVERLAY_PACKAGES, system signature, or shell.
val builder = FabricatedOverlay.Builder("com.rosemary.dynamictheme", "RosemaryAccent",
                                         "com.android.systemui")
builder.setResourceValue("com.android.systemui:color/accent_primary",
                         TypedValue.TYPE_INT_COLOR_ARGB8, 0xFFE91E63.toInt())
val overlay = builder.build()

val mgr = context.getSystemService(OverlayManager::class.java)
val txn = OverlayManagerTransaction.Builder()
    .registerFabricatedOverlay(overlay)
    .setEnabled(overlay.identifier, true, userHandle)
    .build()
mgr.commit(txn)
```

Android 12L tightened FRROs to system/root only — third-party apps can no longer mint them. For a LineageOS-side theme engine or a custom Settings preference that recolors SystemUI live, this is the right primitive.

*   [`FabricatedOverlay` reference](https://developer.android.com/reference/android/content/om/FabricatedOverlay)
*   [`OverlayManagerTransaction` reference](https://developer.android.com/reference/android/content/om/OverlayManagerTransaction)

### 2. Direct XML Modification

This method involves directly editing the XML resource files within the AOSP/LineageOS source tree. This is powerful for precise changes but requires recompilation and flashing of the affected module.

*   **Concept**: Locate the target XML file (e.g., layout, style, dimension) in the source code, modify it, then rebuild and flash the system.
*   **How to Alter (General Steps)**:
    1.  **Locate File**: Navigate to the specific XML file (e.g., `packages/SystemUI/res/layout/status_bar.xml`, `frameworks/base/core/res/res/values/dimens.xml`).
    2.  **Edit XML**: Make your desired changes. This could be:
        *   Changing `android:visibility` of elements to hide/show them.
        *   Adjusting `android:layout_width`, `android:layout_height`, `android:padding`, `android:margin` for spacing and sizing.
        *   Modifying `android:textColor`, `android:textSize` for text appearance.
        *   Rearranging `View` elements within a `ViewGroup`.
    3.  **Recompile**: From your AOSP build environment, use `m <module_name>` (e.g., `m SystemUI`) to recompile the modified module.
    4.  **Flash/Push**: Flash the updated `system.img` or push the specific APK/resource file (`adb push SystemUI.apk /system/priv-app/SystemUI/SystemUI.apk`) and reboot.
*   **Examples of Direct XML Modifications**:
    *   **Status Bar Customizations**:
        *   Modify `packages/SystemUI/res/layout/status_bar.xml` or related layouts to change the position of the clock, battery icon, or notification icons.
        *   Adjust `packages/SystemUI/res/values/dimens.xml` to change icon sizes or padding.
    *   **Quick Settings Panel Layout**:
        *   Edit `packages/SystemUI/res/layout/qs_panel.xml` or `quick_settings_tile.xml` to alter the grid layout, tile size, or text appearance of Quick Settings tiles.
    *   **Notification Styling**:
        *   Modify layouts in `packages/SystemUI/res/layout/notification_template_*.xml` or `frameworks/base/core/res/res/layout/notification_template_*.xml` to change how notifications are displayed (e.g., compacting elements, changing font styles).

## Customization Techniques - Code & Features

### 1. Java/Kotlin Code Patching

This method involves modifying the core Java or Kotlin source files, allowing for deep behavioral changes, new features, and integration with system services.

*   **Concept**: Directly edit `.java` or `.kt` files in `SystemUI`, `frameworks/base`, or other system apps, then rebuild and flash. This provides maximum control but requires significant coding knowledge and careful handling of Android's internal APIs.
*   **How to Modify (General Steps)**:
    1.  **Locate Source Files**: Identify the relevant Java/Kotlin files.
        *   `SystemUI` logic: `packages/SystemUI/src/com/android/systemui/`.
        *   Framework services: `frameworks/base/services/core/java/com/android/server/`.
    2.  **Understand Existing Logic**: Analyze the call stack, dependencies, and existing behavior. Use `adb logcat` and `dumpsys` for runtime inspection.
    3.  **Implement Changes**:
        *   Add new classes or extend existing ones.
        *   Modify methods to alter behavior (e.g., change how gestures are handled, add new logic to a service).
        *   Access system properties or define new ones (`Settings.System`, `Settings.Secure`, `Settings.Global`).
        *   Integrate with internal Android APIs (use caution, as these can change between versions).
    4.  **Build and Flash**: Recompile the affected module (e.g., `m SystemUI`, `m framework-services`) and flash the device.
*   **Examples of Code Patching (Common Custom ROM Features)**:
    *   **Custom Quick Settings Tiles**:
        *   Creating a new custom tile often involves defining a new class that extends `QSTile` (or similar) within the `SystemUI` package.
        *   This class handles the tile's state (on/off), icon, label, and the action performed when tapped.
        *   The tile needs to be registered with the `QSFactory` (or dynamically added to the list of available tiles).
        *   **Key Resources**:
            *   [AOSP Documentation on Quick Settings tiles](https://source.android.com/docs/core/display/quick-settings-tile)
            *   [SystemUI Quick Settings infrastructure (`qs-tiles.md`)](https://android.googlesource.com/platform/frameworks/base/+/ee8f16377a75/packages/SystemUI/docs/qs-tiles.md)
    *   **Advanced Power Menu**: Modifying the `GlobalActions` dialog within `SystemUI` (e.g., `com.android.systemui.globalactions.GlobalActionsDialogLite.java`) to add options like screenshot, screen recorder, or different reboot modes.
    *   **Status Bar Customizations (Logic)**: Implementing network traffic monitors, custom clock formats, or dynamic battery styles often requires Java/Kotlin code to fetch data and update the UI.

#### SystemUI Compose & the Scene Framework ("Flexiglass") — Android 15+

Starting with Android 15 (LineageOS 22.2), large parts of SystemUI are migrating from XML+View hierarchies to **Jetpack Compose** organized around a new "Scene Framework". The Shade, Quick Settings, Lockscreen, and Notification stack are being progressively re-implemented under `packages/SystemUI/compose/{facade,features,scene}/`. If you're targeting lineage-22.2 or later, much of the XML-modification guidance above no longer applies to those surfaces.

Key landmarks once you `cd packages/SystemUI`:

*   `compose/scene/src/com/android/compose/animation/scene/SceneContainer.kt` — the host composable that swaps between scenes (Lockscreen ↔ Bouncer ↔ Shade ↔ QuickSettings)
*   `compose/facade/enabled/...` vs `compose/facade/disabled/...` — `aconfig`-gated dual implementations; the build system picks one based on flag state
*   `aconfig/scene_container_flag.aconfig` and `aconfig/notifications_flags.aconfig` — the on/off switches for the new surfaces

The relevant `aconfig` flags can be flipped at runtime (on `userdebug` builds, without rebuilding) for A/B testing:

```bash
adb shell device_config override systemui com.android.systemui.scene_container true
adb shell device_config override systemui com.android.systemui.notifications_heads_up_refactor true
# List what's currently overridden:
adb shell device_config list systemui | grep -E 'compose|scene|refactor'
# Required after most flag flips: kill SystemUI to pick up the change.
adb shell killall com.android.systemui
```

When patching Compose UI in SystemUI, the workflow is `m SystemUI && adb install -r out/.../SystemUI.apk && adb shell killall com.android.systemui` — same as XML-era patching, but the *what you edit* moves from `res/layout/*.xml` to `compose/.../*.kt`.

Reference: [SystemUI Scene Framework design doc](https://android.googlesource.com/platform/frameworks/base/+/refs/heads/main/packages/SystemUI/docs/scene.md).

### 2. Adding New Settings/Features to the `Settings` Application

Custom ROMs often integrate unique features into the central `Settings` application to provide user control.

*   **Concept**: Add new UI elements (preferences, sections) to `packages/apps/Settings/` to expose custom features. This involves creating XML preference definitions and corresponding Java/Kotlin logic to manage their state and impact.
*   **How to Integrate**:
    1.  **Locate Settings App Source**: The primary directory is `packages/apps/Settings/`.
    2.  **Create Preference XML**: Define the UI for your settings.
        *   Create a new XML file in `res/xml/` (e.g., `res/xml/custom_features_settings.xml`).
        *   Use `PreferenceCategory`, `PreferenceScreen`, `SwitchPreference`, `ListPreference`, etc.
        ```xml
        <?xml version="1.0" encoding="utf-8"?>
        <PreferenceScreen xmlns:android="http://schemas.android.com/apk/res/android">
            <PreferenceCategory android:title="@string/custom_features_category">
                <SwitchPreference
                    android:key="enable_network_traffic_monitor"
                    android:title="@string/network_traffic_monitor_title"
                    android:summary="@string/network_traffic_monitor_summary"
                    android:defaultValue="false" />
                <!-- More preferences -->
            </PreferenceCategory>
        </PreferenceScreen>
        ```
    3.  **Create Preference Fragment/Controller**: Implement a Java/Kotlin class to handle the logic.
        *   Extend `androidx.preference.PreferenceFragmentCompat` or create a `PreferenceController`.
        *   Override `onCreatePreferences` to load your XML.
        *   Implement `onPreferenceChange` listeners to react to user input and persist values (e.g., to `Settings.System` or a custom `SettingsProvider`).
        ```java
        // Example (simplified)
        public class CustomFeaturesFragment extends PreferenceFragmentCompat implements
                Preference.OnPreferenceChangeListener {

            @Override
            public void onCreatePreferences(Bundle savedInstanceState, String rootKey) {
                setPreferencesFromResource(R.xml.custom_features_settings, rootKey);

                SwitchPreference networkTrafficPref = findPreference("enable_network_traffic_monitor");
                if (networkTrafficPref != null) {
                    networkTrafficPref.setOnPreferenceChangeListener(this);
                }
            }

            @Override
            public boolean onPreferenceChange(Preference preference, Object newValue) {
                String key = preference.getKey();
                if ("enable_network_traffic_monitor".equals(key)) {
                    boolean enabled = (Boolean) newValue;
                    // Persist setting to system or custom provider
                    Settings.System.putInt(getContext().getContentResolver(),
                            "network_traffic_monitor_enabled", enabled ? 1 : 0);
                    // Broadcast intent or trigger SystemUI restart if needed
                    return true;
                }
                return false;
            }
        }
        ```
    4.  **Integrate into Settings Hierarchy**:
        *   Add your new fragment to an existing `PreferenceScreen` in `Settings` (e.g., `res/xml/dashboard_tiles_default.xml` or specific category XMLs).
        *   This typically involves adding a new `<Preference>` tag with `android:fragment` pointing to your new `CustomFeaturesFragment` class.
    5.  **Persist Settings**: For system-wide features, use `Settings.System`, `Settings.Secure`, or `Settings.Global` to store and retrieve values. LineageOS provides its own `LineageSettings` provider — see the LineageOS-specific section below for when to use it.

## Customization Techniques - Material You / Dynamic Color

Since Android 12, every system color (accent, neutral, surface, on-surface, etc.) is generated at runtime from the user's wallpaper via the **Monet** color extraction engine. If you're theming SystemUI / Settings / launcher on a modern target, you are working *with* this pipeline — not replacing it.

### Pipeline overview

```
WallpaperManager
     │ (current wallpaper bitmap)
     ▼
WallpaperColors                      ← extracts up to 3 dominant colors
     │
     ▼
com.android.systemui.monet.ColorScheme         ← seeds material color spec
     │
     ▼
accent1[0..10], accent2[0..10], accent3[0..10] ← 13 shades each
neutral1[0..10], neutral2[0..10]
     │
     ▼
ThemeOverlayController                ← creates Fabricated RROs targeting
                                         framework + SystemUI + Settings
     │
     ▼
OverlayManagerService                 ← applies overlays to running system
```

The `ThemeOverlayController` in `packages/SystemUI/src/com/android/systemui/theme/` watches `WallpaperManager` and `Settings.Secure.THEME_CUSTOMIZATION_OVERLAY_PACKAGES`, then commits an `OverlayManagerTransaction` of fabricated overlays — the same FRRO machinery covered above. To customize:

*   **Substitute a different color extractor** — replace `ColorScheme.getSeedColors()` (e.g., to pull from album art, time of day, or a user picker) and the rest of the pipeline keeps working.
*   **Change the palette generation algorithm** — `ColorScheme` uses the AOSP port of Material Color Utilities (HCT color space). Forks like `monet-engine` or LineageOS's accent picker plug in here.
*   **Disable Monet** (e.g., to ship a fixed dark theme) — set `flag_monet` to `false` in `packages/SystemUI/res/values/flags.xml` or override via `device_config`.

Reference: [AOSP — Implement Dynamic Color](https://source.android.com/docs/core/display/dynamic-color).

## LineageOS-Specific UI Infrastructure

Vanilla AOSP documentation often steers you toward `frameworks/base` patches and `Settings.System` keys. LineageOS has parallel infrastructure that you should prefer when shipping Lineage-side features — using it makes your changes survive upstream merges and gives you a clean integration point with the LineageOS Settings UI.

### `LineageSettings` provider (use it instead of `Settings.System` for Lineage-only keys)

LineageOS ships `org.lineageos.platform.internal` providers that expose `LineageSettings.System`, `LineageSettings.Secure`, and `LineageSettings.Global` — same API surface as AOSP's `Settings`, separate storage. Use these for any setting that exists *only* on LineageOS so you're not polluting the AOSP namespace (and so your setting survives if AOSP later defines a key with the same name):

```java
import lineageos.providers.LineageSettings;

// Write:
LineageSettings.System.putInt(getContentResolver(),
    LineageSettings.System.NETWORK_TRAFFIC_MODE, mode);

// Read:
int mode = LineageSettings.System.getIntForUser(getContentResolver(),
    LineageSettings.System.NETWORK_TRAFFIC_MODE, 0, UserHandle.USER_CURRENT);
```

The schema (and validator entries) live in `vendor/lineage/lineage-sdk/src/java/lineageos/providers/LineageSettings.java`. New keys require an entry there plus a migration in `LineageDatabaseHelper`.

### `lineage-sdk` Styles API

For accent / style toggles specifically, `lineageos.style.StyleInterface` exposes a higher-level API on top of OverlayManager — `getTrustedAccents()`, `setAccent()`, `getStyle()` — that the LineageOS Settings accent picker uses. Hooking into this rather than calling `OverlayManager` directly means your custom accents auto-appear in the existing Settings UI.

### `LineageParts` (the home for Lineage-side settings UI)

`packages/apps/LineageParts/` is LineageOS's parallel-to-`Settings` app for Lineage-specific preferences (status bar tweaks, gesture navigation extras, button remapping, etc.). When adding a new Lineage-side feature toggle, add the preference fragment here — *not* in `packages/apps/Settings/`. The main Settings app surfaces LineageParts entries automatically through the `<lineage-additional-settings>` mechanism.

### Trebuchet (not Launcher3) is the launcher

LineageOS ships `packages/apps/Trebuchet/` — a Launcher3 + Quickstep fork with grid/icon-pack/feed deltas. **Launcher patches should be rebased onto Trebuchet, not vanilla Launcher3.** Quickstep gestures (the recents/overview animation logic) live in the same tree. If you're following an AOSP Launcher3 customization tutorial, the file paths usually translate directly to Trebuchet, but the upstream Lineage commits ahead of the AOSP `Launcher3` history may have already done what the tutorial is asking for.

### Vendor-extension pattern: `SystemUIGoogle` / `SystemUIExt`

Direct edits to `packages/SystemUI/src/...` create merge conflicts on every Lineage rebase. The cleaner pattern, originated by `SystemUIGoogle` and used by several custom ROMs, is to ship a separate `system_ext` module that subclasses `SystemUIApplication` and registers additional services through `config_systemUIServiceComponents`:

```
device/xiaomi/rosemary/                # or a vendor/ tree
  system_ext/
    SystemUIExt/
      Android.bp           ← android_app target, name: "SystemUIExt"
      src/...              ← your custom services
      res/values/config.xml ← <string-array name="config_systemUIServiceComponents">
                              extending the base set with your new components.
```

Combine with an RRO that overrides `config_systemUIServiceComponents` in the base SystemUI to include your extension. Upgrade to a new LineageOS branch becomes "rebuild your `SystemUIExt`" rather than "resolve 200 merge conflicts in SystemUI."

## ROM-Adjacent UI Customization

### PixelPropsUtils and Play Integrity

Outside the strict "UI customization" scope but ubiquitous in custom ROM forks: `PixelPropsUtils` is a small framework patch (lives in `frameworks/base/core/java/com/android/internal/util/<rom>/PixelPropsUtils.java` in most forks) that spoofs `Build.FINGERPRINT` / `ro.product.*` props per-process to satisfy Play Integrity device attestation and unlock features gated on Pixel hardware (e.g., Google Photos' unlimited backups, exclusive wallpapers).

LineageOS's official position: **they don't ship it.** The doc at [lineageos.org/PlayIntegrity](https://lineageos.org/PlayIntegrity/) explains why and points users at out-of-tree solutions:

*   **PlayIntegrityFix / PlayIntegrityFork** — Magisk/KernelSU modules that spoof fingerprints at the prop level; updated frequently as Google rolls fingerprints out of the trusted set.
*   **TrickyStore** — KernelSU/APatch module that intercepts `keystore2` attestation calls and returns synthesized attestation that passes hardware-backed verification.

If you're shipping a LineageOS-derivative ROM and want Play Integrity to pass out of the box, the path is patching `PixelPropsUtils` into your framework, *not* bundling a Magisk module — Lineage proper rejects this on policy grounds, but downstream forks routinely do it.

## Build, Flash, and Debug Considerations

*   **Build Process**: After modifying source code, navigate to your AOSP/LineageOS root directory and use `m <module_name>` (e.g., `m SystemUI`, `m Settings`) for specific modules, or `make -jX` for a full build.
*   **Flashing**:
    *   For core system changes, you'll generally need to flash the entire `system.img`, `boot.img`, etc., via `fastboot`.
    *   For app-specific changes (e.g., `SystemUI.apk`), you might be able to push the updated APK directly via `adb push` to `/system/priv-app/SystemUI/` (ensure correct permissions and `adb remount` if needed), followed by a `killall com.android.systemui` or reboot.
*   **Debugging**:
    *   **`adb logcat`**: Essential for viewing system logs, debugging messages, and crash information.
    *   **Android Studio**: Can be set up to debug AOSP components.
    *   **Breakpoints**: Adding `android.os.Debug.waitForDebugger()` in your Java/Kotlin code can pause execution, allowing you to attach a debugger.
    *   **Crash Reports**: Analyze `/data/tombstones` and `/data/anr/` for crash logs.

## Complexity and Impact

*   **Complexity**: UI customization from source varies significantly in complexity.
    *   **Low**: Minor RRO changes (colors).
    *   **Medium**: Direct XML layout modifications, more complex RROs (layouts, custom themes).
    *   **High**: Java/Kotlin code patching, integrating new system settings, implementing entirely new features.
*   **Impact**:
    *   **Stability**: Incorrect code modifications can lead to instability, crashes, or boot loops.
    *   **Maintainability**: Modifying source code makes it harder to merge upstream AOSP/LineageOS updates, as conflicts will arise. RROs are generally more maintainable.
    *   **Performance**: Poorly optimized code can negatively impact system performance and battery life.
    *   **Security**: Introducing vulnerabilities is a risk with extensive code changes.

This `SKILL.md` provides a roadmap for developers interested in deep UI customization within LineageOS/AOSP from source. Start with simpler RROs, gradually move to XML modifications, and only then tackle complex code patching, always understanding the implications of your changes.