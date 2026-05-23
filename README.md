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

### Hardware & Software Prerequisites

Before you start, confirm the build host meets the realistic minimums for a LineageOS 22.2 / 23.x build:

| Resource | Realistic minimum | Comfortable |
|---|---|---|
| RAM | 16 GB + ~16 GB swap | 32 GB+ (linker phases spike past 30 GB) |
| Disk (single branch) | 300 GB | 500 GB+ for ccache and multiple `out/` |
| CPU | 4 cores | 8+ (build time scales near-linearly) |
| OS | Ubuntu 22.04 / 24.04 LTS, x86_64 | — |

Install the toolchain on Ubuntu 24.04:

```bash
sudo apt install -y openjdk-21-jdk-headless gperf ccache unzip zip flex bison \
  android-tools-adb android-tools-fastboot python-is-python3 \
  libssl-dev libxml2-utils xsltproc imagemagick schedtool \
  libncurses-dev lib32z1-dev lib32ncurses-dev
# `repo` is not in apt; install Google's launcher:
mkdir -p ~/bin && curl -fsSL https://storage.googleapis.com/git-repo-downloads/repo \
  -o ~/bin/repo && chmod +x ~/bin/repo
# Ensure ~/bin is on PATH (e.g. fish: `fish_add_path -g $HOME/bin`).
```

## 2. Device-Specific Resources for Redmi Note 10S (rosemary)

> **Shortcut:** if you're following the LineageOS workflow (section 3), you do **not** need to clone any of these manually. `breakfast rosemary` reads `lineage.dependencies` from the device tree and fetches all of them automatically via the `roomservice.xml` manifest. The listings below exist as a reference for what gets pulled and where, and for users building an AOSP base (rather than LineageOS) who need to wire them in by hand.

Here are the essential GitHub repositories for the Redmi Note 10S from the **official LineageOS project**, which are actively maintained.

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

-   For LineageOS, these are extracted from a **stock MIUI ROM** for the device. The `LineageOS/android_device_xiaomi_rosemary` device tree provides:
    *   `extract-files.py`: A thin wrapper around the LineageOS [`extract_utils`](https://github.com/LineageOS/android_tools_extract-utils) framework (located at `tools/extract-utils/`, pulled in automatically by `repo sync`). On modern branches (lineage-22.2 and newer) this script no longer requires a live device — it can take a stock-ROM payload directly.
    *   `proprietary-files.txt`: The manifest of files to extract.

-   **Three extraction sources are supported** (pick whichever matches what you have):
    ```bash
    cd device/xiaomi/rosemary

    # (1) From a connected device running a compatible stock MIUI ROM (legacy method):
    ./extract-files.py adb

    # (2) From a stock ROM zip / fastboot package:
    ./extract-files.py /path/to/miui_ROSEMARYGlobal_*.zip

    # (3) From an already-extracted system+vendor image dump folder:
    ./extract-files.py /path/to/dumped/rom/folder/
    ```
    Pulled files land in `vendor/xiaomi/rosemary/` (and `vendor/xiaomi/rosemary-common/` for shared blobs across the rosemary/rosemary_p/maltose/secret family).

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

1.  **Initialize your LineageOS workspace** with one of the branches that has official rosemary support. As of 2026 the available branches are `lineage-20`, `lineage-21`, `lineage-22.2` (Android 15 QPR2), `lineage-23.0` (Android 16), and `lineage-23.2` (Android 16 QPR2 — current rolling default). Note that `lineage-22.0` and `lineage-23.0` (with `.0`) were not cut for many devices — Lineage skipped straight to the `.2` QPR rebase for those releases.
    ```bash
    mkdir -p ~/android/lineage
    cd ~/android/lineage
    repo init -u https://github.com/LineageOS/android.git -b lineage-23.2
    # First-sync optimization: skip historical refs and stale projects to save tens of GB.
    repo sync -c --no-clone-bundle --no-tags --optimized-fetch --prune -j$(nproc --all)
    ```
    > **Note:** if you ever `repo init` to a *different* branch in an existing tree (e.g., upgrading lineage-21 → lineage-23.2), add `--force-sync` to the `repo sync` line. Without it, projects whose HEAD has moved fail with `Cannot fetch ... cannot overwrite a local work tree`. `--force-sync` is safe when you have no uncommitted local changes (which is the normal case in a build-only tree).
2.  **Set up the device tree and dependencies in one shot** with the LineageOS `breakfast` helper. This reads `lineage.dependencies` from the rosemary device tree and clones device/kernel/HAL/sepolicy repos automatically via `roomservice.xml` — so you don't have to do section 2's clones by hand.
    ```bash
    source build/envsetup.sh
    breakfast rosemary
    ```
    > Watch the codename: rosemary, rosemary_p, maltose, and secret share one device tree but have **distinct** `lineage_<codename>.mk` product files. Picking the wrong one is the #1 way builders brick the modem on these phones.
3.  **Extract Vendor Blobs** (as described in section 2.C).
4.  **Build and package the ROM** with `brunch` (combined `lunch` + `mka bacon` + zip):
    ```bash
    brunch rosemary
    ```
    Or, if you want the lower-level pieces explicitly: `lunch lineage_rosemary-userdebug && mka bacon -j$(nproc --all)`. Either way the final flashable zip lands in `out/target/product/rosemary/lineage-*.zip`.

**IMPORTANT:** Always refer to the specific `README.md` files within each linked repository and the official LineageOS/AOSP documentation for the most accurate and up-to-date instructions. Building custom ROMs requires patience and attention to detail.

## 4. Build Performance & Reproducibility

### ccache (essential, not optional)

Without ccache, every `brunch` after a clean recompiles everything; with a warm cache, incremental builds finish in tens of minutes instead of hours. Since Android 10 (Q), Google stopped shipping a prebuilt ccache, so **you must point AOSP at the system binary explicitly** — otherwise ccache stays silently inactive.

```bash
# Add to ~/.bashrc / ~/.config/fish/config.fish:
export USE_CCACHE=1
export CCACHE_EXEC=$(which ccache)            # mandatory since Android Q
export CCACHE_DIR=$HOME/.ccache               # default; override if you want it on a fast SSD
# One-time sizing (50 GB is enough for one branch; bump to 100 GB if you build multiple):
ccache -M 50G
ccache -o compression=true
ccache -o compression_level=6
```

Verify with `ccache -s` after a build — `cache hit (direct)` should be non-zero after the second build.

### Build identity (optional, makes your builds attributable)

Set these before `breakfast` to control what shows up in `Settings → About phone → Build number` and `uname -a`:

```bash
export BUILD_USERNAME=$(whoami)
export BUILD_HOSTNAME=$(hostname)
export KBUILD_BUILD_USER=$BUILD_USERNAME      # used by the kernel build
export KBUILD_BUILD_HOST=$BUILD_HOSTNAME
export KBUILD_BUILD_TIMESTAMP="$(date -u)"    # set this to a fixed value if you want reproducible builds
```

## 5. Flashing on Rosemary — Critical Pitfalls

Three things bite first-time rosemary builders. Internalize them before you flash:

1.  **Codename mismatch bricks the modem.** rosemary, rosemary_p, maltose, and secret share the device tree but have distinct `lineage_<codename>.mk` product files (different baseband / NV partitions). Picking the wrong one in `breakfast` produces a zip that boots but **kills modem firmware loading** — and recovery requires the variant-correct stock fastboot package. Confirm your variant from `Settings → About phone → Model number` against the [variants page](https://wiki.lineageos.org/devices/rosemary/) before building.

2.  **Stock vbmeta will refuse the unsigned boot image.** Before flashing the Lineage `boot.img`, disable verified boot:
    ```bash
    fastboot --disable-verity --disable-verification flash vbmeta vbmeta.img
    # or flash an empty vbmeta:
    fastboot flash vbmeta empty_vbmeta.img
    ```
    Without this, you'll bootloop into the orange "your device's bootloader is unlocked" screen.

3.  **`dtbo.img` is a separate partition on rosemary** (not embedded in `boot`). After flashing `boot.img`, also flash:
    ```bash
    fastboot flash dtbo dtbo.img
    ```
    Otherwise the kernel boots but display / touch / sensors silently fail.

> **Kernel note:** rosemary uses the MediaTek MT6785 vendor kernel (Linux 4.19) — it is **not** GKI. Community generic kernels and `vendor_boot` patterns from Pixel devices do not apply here. Persistent kernel logs come from `/sys/fs/pstore/console-ramoops-0` (see `ROM_Debugging_SKILL.md` §5), not the legacy `/proc/last_kmsg`.

## 6. Signing Builds for Distribution (optional)

By default `brunch` produces a zip signed with AOSP's public test keys (`build/target/product/security/test*.x509.pem`). That's fine for personal testing but means:
- Every fresh build is treated as a different app signer → addonsu, OTA updates, and any side-loaded app that pins by signature break on re-flash.
- The build is trivially impersonable.

For a build you intend to distribute or run as a daily driver, generate a personal keyset once and re-sign the target-files package:

```bash
mkdir -p ~/.android-certs
# In your AOSP tree:
for x in releasekey platform shared media networkstack; do
  ./development/tools/make_key ~/.android-certs/$x '/C=US/ST=California/L=Mountain View/O=Android/OU=Android/CN=Android/emailAddress=android@android.com'
done

# Build target-files + otatools, then sign:
brunch rosemary
m target-files-package otatools
sign_target_files_apks -o \
  --default_key_mappings ~/.android-certs \
  out/target/product/rosemary/obj/PACKAGING/target_files_intermediates/lineage_rosemary-target_files-*.zip \
  signed-target_files.zip
ota_from_target_files -k ~/.android-certs/releasekey signed-target_files.zip lineage-rosemary-signed.zip
```

Reference: [LineageOS — Signing your builds](https://wiki.lineageos.org/signing_builds).

## 7. Adding Google Apps (MindTheGapps)

LineageOS does **not** ship Google Mobile Services — there is no `WITH_GMS=true` build flag despite what older AOSP guides may suggest. To get the Play Store, Play Services, etc., flash a GApps package **separately after** flashing LineageOS but **before** first boot:

- **MindTheGapps** ([downloads.lineageos.org/sweet/MindTheGapps/](https://downloads.lineageos.org/sweet/MindTheGapps/)) — the variant Lineage officially documents; matched per Android version.
- Other options (NikGapps, BiTGApps) exist but are not Lineage-blessed.

Flash via TWRP/OrangeFox recovery after sideloading the Lineage zip. Reboot directly to recovery (not into Android) between the two zips to avoid GApps install failing on `/system` permissions.
