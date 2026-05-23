# SKILL: LineageOS/AOSP UI Customization from Source

## Introduction

This document outlines techniques for customizing the User Interface (UI) within LineageOS or AOSP (Android Open Source Project) by modifying its source code. These methods range from simple resource overlays for theming to complex code patching for new features. Understanding these techniques is crucial for custom ROM developers, device maintainers, and anyone looking to deeply personalize their Android experience.

**Disclaimer**: Modifying the AOSP/LineageOS source requires a strong understanding of Android's architecture, Java/Kotlin programming, and the Android build system. Improper modifications can lead to device instability, boot loops, or security vulnerabilities. Always proceed with caution, back up your work, and test thoroughly.

## Prerequisites

Before attempting any UI customization from source, ensure you have the following:

1.  **AOSP/LineageOS Build Environment**: A fully set up environment capable of compiling Android from source. This typically includes:
    *   A Linux-based operating system (Ubuntu is common).
    *   Sufficient RAM (min 16GB, 64GB recommended) and disk space (min 250GB, 500GB+ recommended).
    *   Required build tools and libraries (OpenJDK, `repo`, `git`, `gperf`, `ccache`, etc.). Refer to `source.android.com/docs/setup/start/requirements` for detailed setup.
2.  **Cloned AOSP/LineageOS Source Tree**: The complete source code for the Android version you intend to modify, synced using the `repo` tool.
3.  **Basic Android Development Knowledge**: Familiarity with Android app development (activities, services, layouts, resources) and Java/Kotlin.
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
    5.  **Persist Settings**: For system-wide features, use `Settings.System`, `Settings.Secure`, or `Settings.Global` to store and retrieve values. LineageOS often has its own `LineageSettings` provider.

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