# Redmi Note 10S (rosemary) Custom ROM Building Resources

This document provides resources and links to get started with building custom Android ROMs for the Redmi Note 10S (codename: rosemary, rosemary_p, maltose, secret).

## 1. Introduction to Custom ROM Building

Building a custom ROM involves several key steps:
1.  **Setting up a build environment:** Typically a powerful Linux distribution (Ubuntu is highly recommended).
2.  **Downloading the AOSP (Android Open Source Project) source code:** This forms the base of your ROM.
3.  **Syncing device-specific repositories:** These include the device tree, kernel source, and vendor blobs, which tell Android how to interact with your phone's unique hardware.
4.  **Configuring the build:** Selecting the target device, build type (e.g., userdebug), and any optional features.
5.  **Compiling the ROM:** This is a resource-intensive process that can take many hours.
6.  **Flashing the ROM:** Installing the compiled ROM onto your device (requires unlocked bootloader and custom recovery).

For detailed general guides on the custom ROM building process, refer to:
-   [Build Custom ROM from Source - Complete Developer Guide](https://thecustomrom.com/guides/build-custom-rom)
-   [How to build your own custom Android ROM - Android Authority](https://www.androidauthority.com/build-custom-android-rom-720453/)
-   [LineageOS Wiki - Build Instructions](https://wiki.lineageos.org/compile) (Excellent general guide for LineageOS-based ROMs)

## 2. Device-Specific Resources for Redmi Note 10S (rosemary)

Here are the essential GitHub repositories for the Redmi Note 10S from the **official LineageOS project**, which are actively maintained. You will need to clone these into your AOSP/LineageOS source tree at the appropriate paths.

### A. Device Tree (`device/xiaomi/rosemary`)
The device tree defines how Android interacts with your specific device hardware (e.g., partitions, sensors, display).
-   **Official LineageOS Device Tree:** [`LineageOS/android_device_xiaomi_rosemary`](https://github.com/LineageOS/android_device_xiaomi_rosemary)
    *   **Clone command:**
        ```bash
        git clone https://github.com/LineageOS/android_device_xiaomi_rosemary.git device/xiaomi/rosemary
        ```

### B. Kernel Source (`kernel/xiaomi/mt6785`)
The kernel is the core of the operating system, managing hardware resources.
-   **Official LineageOS Kernel Source:** [`LineageOS/android_kernel_xiaomi_mt6785`](https://github.com/LineageOS/android_kernel_xiaomi_mt6785)
    *   **Clone command:**
        ```bash
        git clone --depth=1 https://github.com/LineageOS/android_kernel_xiaomi_mt6785.git kernel/xiaomi/mt6785
        ```
        *Note: `--depth=1` performs a shallow clone, which is faster and sufficient for building.*

### C. Vendor Blobs (Proprietary Files)
These are closed-source binaries provided by the manufacturer (Xiaomi) that are necessary for certain hardware components to function. You cannot build a fully functional ROM without these.
-   For LineageOS, these are typically extracted directly from a **stock MIUI ROM** installed on your device. The `LineageOS/android_device_xiaomi_rosemary` device tree includes:
    *   `extract-files.py`: A script to pull files from your device.
    *   `proprietary-files.txt`: A list of files to be extracted.
-   **How to obtain:**
    1.  Install a stock MIUI ROM on your Redmi Note 10S.
    2.  Enable ADB debugging on your device.
    3.  Connect your device to your computer.
    4.  Navigate to your `device/xiaomi/rosemary` directory in your build environment.
    5.  Run the extraction script:
        ```bash
        cd device/xiaomi/rosemary
        ./extract-files.py
        ```
    This process will pull the necessary proprietary files and place them into the correct `vendor/xiaomi/rosemary` directory in your build environment.

### D. Other LineageOS Dependencies
These are additional hardware abstraction layers and SEPolicy rules required for the device.
-   **Mediatek SEPolicy Vendor:** [`LineageOS/android_device_mediatek_sepolicy_vndr`](https://github.com/LineageOS/android_device_mediatek_sepolicy_vndr)
    *   **Clone command:**
        ```bash
        git clone https://github.com/LineageOS/android_device_mediatek_sepolicy_vndr.git device/mediatek/sepolicy_vndr
        ```
-   **Mediatek Hardware Abstraction:** [`LineageOS/android_hardware_mediatek`](https://github.com/LineageOS/android_hardware_mediatek)
    *   **Clone command:**
        ```bash
        git clone https://github.com/LineageOS/android_hardware_mediatek.git hardware/mediatek
        ```
-   **Xiaomi Hardware Abstraction:** [`LineageOS/android_hardware_xiaomi`](https://github.com/LineageOS/android_hardware_xiaomi)
    *   **Clone command:**
        ```bash
        git clone https://github.com/LineageOS/android_hardware_xiaomi.git hardware/xiaomi
        ```

## 3. General Workflow Outline (Simplified)

This is a high-level overview. Each step requires careful execution and troubleshooting.

1.  **Initialize your AOSP/LineageOS workspace:**
    ```bash
    mkdir -p ~/android/lineage # Create a directory for your build environment
    cd ~/android/lineage
    repo init -u https://github.com/LineageOS/android.git -b lineage-21.0 # Example for LineageOS 21 (Android 14). Adjust branch for desired Android version (e.g., lineage-22.0 for Android 15, lineage-23.0 for Android 16).
    repo sync -j$(nproc --all) # Sync the entire AOSP/LineageOS source tree. This will take a very long time and significant disk space.
    ```
2.  **Clone device-specific repositories into your source tree (as listed above).**
3.  **Extract Vendor Blobs** (as described in section 2.C).
4.  **Set up build environment and build the ROM:**
    ```bash
    source build/envsetup.sh
    lunch lineage_rosemary-userdebug # This command will select your target device and build type.
    m -j$(nproc --all) # Start the compilation process. This will take many hours.
    ```

**IMPORTANT:** Always refer to the specific `README.md` files within each linked repository and the official LineageOS/AOSP documentation for the most accurate and up-to-date instructions. Building custom ROMs requires patience and attention to detail.
