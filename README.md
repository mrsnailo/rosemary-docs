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

#### Recommended: clone the pre-extracted TheMuppets repo
For end-user builds, the LineageOS community's `TheMuppets` org publishes a ready-to-use vendor blob repo per device, curated by the device maintainer against a known-good MIUI build (with any IMS/VoLTE smali fixups already applied). This skips the whole `extract-files.py` dance:

```bash
# Install git-lfs first (one-time, system-wide):
sudo apt install -y git-lfs && git lfs install

# Then clone. The MTK radio firmware blobs (audio_dsp.img, md1img.img, lk.img,
# gz.img, cam_vpu*.img, etc. ~77 MB total) are stored via Git LFS, so a plain
# `git clone` leaves you with 100-byte pointer files instead of the real .img
# files — and the build will fail at the kati stage with `radio/audio_dsp.img
# SHA1 mismatch`. The --git-lfs-include flag pulls the binaries during clone:
git clone --depth=1 -b lineage-23.2 \
  --filter=blob:none \
  https://github.com/TheMuppets/proprietary_vendor_xiaomi_rosemary \
  vendor/xiaomi/rosemary
( cd vendor/xiaomi/rosemary && git lfs install --local && git lfs pull )
```

If you already cloned without LFS and got the SHA1 mismatch error, just `cd vendor/xiaomi/rosemary && git lfs install --local && git lfs pull` to fetch the blobs and re-run `brunch`.

To keep TheMuppets in sync on future `repo sync` runs, add it to `.repo/local_manifests/roomservice.xml` (note the `clone-depth="1"` keeps things shallow, and `repo init -b lineage-23.2 --git-lfs` once on the parent tree ensures `repo sync` knows to pull LFS objects):
```xml
<project path="vendor/xiaomi/rosemary"
         remote="github"
         name="TheMuppets/proprietary_vendor_xiaomi_rosemary"
         revision="lineage-23.2"
         clone-depth="1" />
```

After this clone, `vendor/xiaomi/rosemary/rosemary-vendor.mk` exists and `breakfast rosemary` succeeds.

#### Advanced: regenerate blobs from a stock ROM with `extract-files.py`

Only needed if you're a device-tree maintainer producing a new `TheMuppets` snapshot, or you specifically want to bind to a different MIUI version than what TheMuppets publishes. The `LineageOS/android_device_xiaomi_rosemary` device tree provides:
-   `extract-files.py`: a wrapper around [`extract_utils`](https://github.com/LineageOS/android_tools_extract-utils) (vendored at `tools/extract-utils/`, pulled automatically by `repo sync`).
-   `proprietary-files.txt`: blob manifest — pinned against a specific MIUI build (header comment names it, e.g. `V14.0.17.0.TFFMIXM`).

```bash
cd device/xiaomi/rosemary
./extract-files.py /path/to/rosemary_p_global_images_V14.0.17.0.TFFMIXM.tgz

# If the stock ROM has drifted from the manifest (newer build, missing files, hash mismatches):
./extract-files.py --regenerate --kang /path/to/stock.tgz
# --regenerate rewrites proprietary-files.txt to match what's actually in the source;
# --kang accepts whatever hash is in the source instead of failing on pin mismatch.
```

**Known gotchas on lineage-23.2 (December 2025 / January 2026):**

1.  **The blob source must be the `rosemaryp` (TFF region) fastboot tgz** — not the variant ROM that matches your physical device. The device tree's `proprietary-files.txt` was generated against a TFF (rosemaryp/POCO M5s) MIUI build; pulling from a `maltose` (TKL) or `secret` (TLR) ROM produces ~30 "file not found" errors for camera/IMS libs that only exist in the rosemaryp sensor layout. This is fine for the *build* because the runtime variant detection (init_rosemary.cpp) handles maltose/secret quirks anyway — but the *blob set* itself has to come from TFF.

2.  **`extract_utils` has a firmware double-move bug** that aborts extraction of fastboot `.tgz` packages with:
    ```
    shutil.Error: Destination path '/tmp/.../audio_dsp.img' already exists
    ```
    Cause: `_move_files()` iterates `[file.src, file.dst]` even when `src == dst`; the second iteration tries to "move" the already-moved firmware partition image onto itself. Patch is in this repo at [`patches/0001-extract_utils-fix-firmware-double-move.patch`](patches/0001-extract_utils-fix-firmware-double-move.patch). Apply it before extracting:
    ```bash
    cd tools/extract-utils && git apply ~/work/rosemary/patches/0001-*.patch
    ```

3.  **The device tree's IMS/WFC smali patches expect specific MIUI bytecode** and may fail with `Rejected hunk #N` against a stock ROM newer than the one the maintainer used. If this happens, `--regenerate --kang` will drop the affected entries rather than fail the build; the lost functionality is VoLTE/video-telephony, which most users replace post-install anyway.

Pulled files land in `vendor/xiaomi/rosemary/` (and `vendor/xiaomi/rosemary-common/` for shared blobs across the family).

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
    sudo apt install -y git-lfs && git lfs install   # one-time, system-wide
    repo init -u https://github.com/LineageOS/android.git -b lineage-23.2 --git-lfs
    # First-sync optimization: skip historical refs and stale projects to save tens of GB.
    repo sync -c --no-clone-bundle --no-tags --optimized-fetch --prune -j$(nproc --all)
    ```
    > **Note:** if you ever `repo init` to a *different* branch in an existing tree (e.g., upgrading lineage-21 → lineage-23.2), add `--force-sync` to the `repo sync` line. Without it, projects whose HEAD has moved fail with `Cannot fetch ... cannot overwrite a local work tree`. `--force-sync` is safe when you have no uncommitted local changes (which is the normal case in a build-only tree).
    >
    > **Note — LineageOS itself uses Git LFS for prebuilts.** `external/chromium-webview/prebuilt/{arm,arm64,x86,x86_64}/webview.apk` (~247 MB for arm64 alone) is stored via Git LFS. Without `--git-lfs` at `repo init` time, those APKs come down as ~130-byte pointer files, and the build dies hours later at `//external/chromium-webview:webview verify <uses-library>` with `aapt2 ... error: failed opening zip: Invalid file.` If you forgot the flag and only discover this mid-build, the fix is per-subdir: `for a in arm arm64 x86 x86_64; do (cd external/chromium-webview/prebuilt/$a && git lfs install --local && git lfs pull); done`. (TheMuppets vendor blobs are LFS-tracked too — see §2.C — but they live outside the LineageOS manifest, so `--git-lfs` on the parent tree alone does not cover them; pull LFS in `vendor/xiaomi/rosemary` separately.)
2.  **Set up the device tree and dependencies in one shot** with the LineageOS `breakfast` helper. This reads `lineage.dependencies` from the rosemary device tree and clones device/kernel/HAL/sepolicy repos automatically via `roomservice.xml` — so you don't have to do section 2's clones by hand.
    ```bash
    source build/envsetup.sh
    breakfast rosemary
    ```
    > **One build target, five physical variants.** The rosemary device tree ships a *single* `lineage_rosemary.mk` (the only entry in `AndroidProducts.mk`). All five physical Xiaomi codenames — `rosemary` (Redmi Note 10S NFC, M2101K7BNY), `maltose` (RN10S India, M2101K7BL), `secret` (RN10S Latin America, M2101K7BG), `rosemaryp` (POCO M5s, 2207117BPG), `secretr` (Redmi Note 11 SE, 22087RA4DI) — build from the same `breakfast rosemary` command. `init_rosemary.cpp` detects the running hardware at boot and applies per-variant properties. So you can't pick the "wrong" build target; you'd just get "no such device" if you tried `breakfast secret`. (Where the variant *does* matter: vendor blob extraction in §2.C, stock firmware in §5.)

    > **Expected first-time error — don't panic.** On a fresh tree, `breakfast rosemary` clones the device/kernel/HAL repos correctly, then immediately runs `dumpvars` to validate the product spec. That validation fails with `vendor/xiaomi/rosemary/rosemary-vendor.mk does not exist..` and the misleading `** Don't have a product spec for: 'lineage_rosemary'  ** Do you have the right repo manifest?` The `rosemary-vendor.mk` file is shipped by the **vendor blob repo** (`TheMuppets/proprietary_vendor_xiaomi_rosemary`, see §2.C) — `breakfast` does *not* clone it for you. Land the vendor blobs first; the second `breakfast rosemary` then succeeds.
3.  **Get the vendor blobs in place** (one-line `git clone` per §2.C, recommended path). After this, re-run `breakfast rosemary` — it should now print the full `TARGET_PRODUCT=lineage_rosemary` banner.
4.  **Build and package the ROM** with `brunch` (combined `lunch` + `mka bacon` + zip):
    ```bash
    brunch rosemary
    ```
    Or, if you want the lower-level pieces explicitly: `lunch lineage_rosemary bp4a userdebug && mka bacon -j$(nproc --all)` (lineage-23.2 uses `bp4a` as `aosp_target_release` — see `vendor/lineage/vars/aosp_target_release`; earlier branches use different release names). Either way the final flashable zip lands in `out/target/product/rosemary/lineage-*.zip`.

    > **Shell-aliasing gotcha:** lunch parses its single-arg form (`lineage_rosemary-bp4a-userdebug`) with `echo $1 | grep "-"`. Some shells (Claude Code's CLI in particular, but also some user setups that alias `grep` to `rg`/`ugrep`) re-route `grep` to a tool that doesn't accept a bare `-` as a pattern — the test returns empty, parsing falls through to the wrong branch, and `lunch` then treats the whole `lineage_rosemary-bp4a-userdebug` string as `TARGET_PRODUCT`, failing with `Cannot locate config makefile for product`. Workaround: `unset -f grep` (or `unalias grep`) before sourcing `build/envsetup.sh`, or pass the three components as separate args (`lunch lineage_rosemary bp4a userdebug`) to bypass the legacy parser entirely.

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

### Verifying a fresh build before flashing

Always run these four checks against `out/target/product/rosemary/*.zip` before you flash a freshly-baked build onto the phone — they take under a minute and catch the most common "I have a corrupt zip / missing partition / wrong fingerprint" classes of bug:

```bash
cd ~/android/lineage/out/target/product/rosemary

# 1. Build exit status — must be 0 and end with "build completed successfully".
grep -E "^=== brunch.*EXIT|build completed successfully" ~/android/lineage/brunch.run.log | tail -2

# 2. SHA-256 sidecar verification (build also produces .sha256sum next to the zip):
sha256sum --check lineage-*-rosemary.zip.sha256sum

# 3. Zip-level integrity (decompresses every member, checks CRCs, prints "No errors detected"):
unzip -t lineage-*-rosemary.zip | tail -1

# 4. boot.img header sanity (magic, OS version, patch level, embedded DTB on MT6785):
~/android/lineage/out/host/linux-x86/bin/unpack_bootimg --boot_img boot.img | head -20
# Expect: magic ANDROID!, os version 16.0.0, header version 2, dtb size > 0.
```

Two deeper checks worth running once when you set up a new branch (catches drift between what the device tree thinks it's shipping and what the OTA payload actually contains):

```bash
# 5. List every partition the OTA payload will actually write — for rosemary on
#    lineage-23.2 you should see ~21 partitions including modem (md1img), lk, gz,
#    scp, sspm, tee, audio_dsp, cam_vpu{1,2,3}, vbmeta*, plus the obvious
#    system/vendor/product/system_ext/boot/dtbo. If md1img is missing you'll
#    have no cellular signal post-flash.
mkdir -p /tmp/payload_check && cd /tmp/payload_check
unzip -o ~/android/lineage/out/target/product/rosemary/lineage-*-rosemary.zip payload.bin >/dev/null
cd ~/android/lineage
PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION=python \
  PYTHONPATH=system/update_engine/scripts \
  python3 -c "
import update_payload
p = update_payload.Payload('/tmp/payload_check/payload.bin'); p.Init()
for part in p.manifest.partitions:
    print(f'  {part.partition_name:22s} {part.new_partition_info.size/1024/1024:>8.1f} MB')
print(f'total: {len(p.manifest.partitions)} partitions')"

# 6. OTA recipient whitelist — the zip will REFUSE to install on a phone whose
#    ro.product.device is not in this list. For rosemary you want to see all
#    five physical variants comma-joined.
unzip -p ~/android/lineage/out/target/product/rosemary/lineage-*-rosemary.zip \
  META-INF/com/android/metadata | grep ^pre-device=
# Expect: pre-device=rosemary,rosemary_p,secret,secretr,maltose
```

If any of steps 1–6 fails, **do not flash that zip** — the build is broken and flashing it risks a bootloop or a dead modem. Re-run `brunch rosemary` (incremental is fast if ccache is warm) and re-verify.

## 5. Flashing on Rosemary — Critical Pitfalls

Three things bite first-time rosemary builders. Internalize them before you flash:

1.  **Wrong-variant *stock firmware* base bricks the modem** (not the wrong build target — there's only one of those). The LineageOS build is one and the same for all five physical variants (see §3 step 2), but the preloader / lk / modem / vbmeta partitions in **stock MIUI** differ per variant. Flashing, say, a `maltose` global MIUI fastboot package onto a `secret` (Latin America) unit before sideloading LineageOS can render the modem unloadable. Always confirm your variant from `Settings → About phone → Model number` against this table before downloading a stock firmware:

    | Model # | Codename | LineageOS wiki page |
    |---|---|---|
    | M2101K7BNY | rosemary | [variant1](https://wiki.lineageos.org/devices/rosemary/variant1/) (NFC) or variant2 |
    | M2101K7BL  | maltose  | variant1 (India, no NFC) |
    | M2101K7BG  | secret   | [variant3](https://wiki.lineageos.org/devices/rosemary/variant3/) (Latin America) |
    | 2207117BPG | rosemaryp | [variant4](https://wiki.lineageos.org/devices/rosemary/variant4/) (POCO M5s) |
    | 22087RA4DI | secretr  | (Redmi Note 11 SE — not officially a rosemary variant) |

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

4.  **The LineageOS zip already ships firmware — you usually do NOT need a separate MIUI fastboot-firmware flash.** Both `rosemary_variant1.yml` and `rosemary_variant3.yml` in the LineageOS wiki set `ships_fw: true`, and a brunch-baked zip contains a 21-partition `payload.bin` that includes `md1img` (modem), `lk` (little kernel), `gz`, `scp`, `sspm`, `spmfw`, `tee`, `audio_dsp`, `cam_vpu1/2/3`, `preloader_raw`, and all three `vbmeta*` partitions on top of `boot/dtbo/system/vendor/product/system_ext`. **Expected size on lineage-23.2: ~1.1-1.5 GB** (verified 2026-05-24: 1131 MB zip with all 21 partitions). Older guides quoting 3-4 GB pre-date modern payload compression — a 1 GB zip is NOT a missing-partition red flag; always confirm by inspecting the manifest (next step), not the file size. Confirm with the §4 step 5 check before flashing. The pre-flash MIUI firmware step is only needed if (a) your phone is on a MIUI version older than 13 — the bootloader/preloader has to be modern enough to accept the unsigned bootimg, or (b) you want to be able to relock the bootloader / roll back to stock later.

5.  **TKL vs TFF — which MIUI baseline if you do need one.** `init_rosemary.cpp` carries `V14.0.11.0.TKLMIXM` as maltose's reference *fingerprint string*, but the [LineageOS wiki firmware-update page](https://wiki.lineageos.org/devices/rosemary/firmware_update_xiaomi_rosemary/) for all rosemary variants — including variant1 (Global, where Indian maltose lives) and variant3 (Latin America) — points to **`V14.0.17.0.TFFMIXM`** (global TFF region, filename `miui_ROSEMARYPGlobal_V14.0.17.0.TFFMIXM_b6ba1e953f_13.0.zip`, ~6 GB) as the single canonical fastboot ROM baseline for all five variants. The TKL string is a per-variant fingerprint *label* set at runtime by init, not a hard requirement on which partition images you must flash. If you flash MIUI firmware as a precaution, use the TFF tgz unless your specific phone refuses it.

> **Kernel note:** rosemary uses the MediaTek MT6785 vendor kernel (Linux 4.19) — it is **not** GKI. Community generic kernels and `vendor_boot` patterns from Pixel devices do not apply here. Persistent kernel logs come from `/sys/fs/pstore/console-ramoops-0` (see `ROM_Debugging_SKILL.md` §5), not the legacy `/proc/last_kmsg`.

### Pre-install checklist

Before the first flash, confirm each of these is true on your phone *and* on the build machine:

- **Bootloader unlocked.** Settings → About → Tap MIUI version 7×, enable Developer Options → enable "OEM unlocking" and "USB debugging" → bind the phone to a Mi account → run [Mi Unlock Tool](https://en.miui.com/unlock/) and wait out the cooldown (168 h originally, shortened for some accounts/devices). Verify with `fastboot getvar unlocked` — must print `yes`.
- **Phone is on MIUI 13 or newer.** Anything older needs a stock-firmware update first, because the preloader signature on older MIUI rejects modern bootimg layouts.
- **adb / fastboot ≥ 33.0.0** on the build/flash machine. Older versions miss the `--disable-verity --disable-verification` flag combo. `fastboot --version` to check.
- **USB-A 2.0 cable into a USB-A 2.0 host port** (or a powered USB-2 hub). MT6785's bootloader USB stack is unreliable on USB-C-to-C cables and on USB-3 host ports — `fastboot getvar` will randomly hang. This is documented on the LineageOS wiki for rosemary.
- **Battery ≥ 60 %.** A sideload that loses power mid-write trashes the super partition and you'll need fastbootd to recover.
- **Variant confirmed.** `Settings → About → Model number` matches one of the rows in the §5 #1 table. Knowing the variant matters mostly for "if I need to flash MIUI firmware, which one", since the LineageOS build itself is variant-agnostic (one zip, all five variants).
- **The build passes all six checks in §4 → "Verifying a fresh build before flashing".**
- **You have a known-good MIUI fastboot ROM downloaded as a safety net** (the TFF tgz above), even if you don't plan to flash it first. If LineageOS bricks the modem, you'll want it handy without an internet round-trip.

### Recommended install sequence (UNOFFICIAL / testkey build, from booted MIUI 13+)

This is the minimum-step path. It does NOT pre-flash MIUI firmware, relying on the LineageOS zip's own firmware-shipping behavior (see §5 #4).

```bash
# (1) From booted MIUI, reboot to fastboot.
adb reboot bootloader
fastboot getvar unlocked       # → unlocked: yes
fastboot getvar product        # → product: rosemary  (or rosemary_p / secret / etc — any of the 5 is fine)

# (2) Disable AVB verification. Required because the build is signed with AOSP
#     test-keys, not your phone's OEM root. Without this you get "your device is
#     corrupt" at every boot. Flash to BOTH slots on this A/B device.
fastboot --disable-verity --disable-verification flash vbmeta_a   vbmeta.img
fastboot --disable-verity --disable-verification flash vbmeta_b   vbmeta.img
fastboot --disable-verity --disable-verification flash vbmeta_system_a vbmeta_system.img
fastboot --disable-verity --disable-verification flash vbmeta_system_b vbmeta_system.img

# (3) Flash boot.img (which IS the LineageOS recovery — BOARD_USES_RECOVERY_AS_BOOT=true).
fastboot flash boot_a boot.img
fastboot flash boot_b boot.img

# (4) Flash dtbo.img (separate partition on rosemary, kernel-versioned together).
fastboot flash dtbo_a dtbo.img
fastboot flash dtbo_b dtbo.img

# (5) Reboot straight into the freshly-flashed LineageOS recovery — DO NOT
#     allow it to boot system first; that would overwrite recovery on next OTA
#     and leave you without one. The screen will show the LineageOS logo.
fastboot reboot recovery

# (6) Inside LineageOS Recovery (touchscreen menu):
#     "Factory reset" → "Format data / factory reset"   (mandatory; switches
#         from MIUI's dm-crypt to LOS metadata encryption — wipes /data)
#     Then back → "Apply update" → "Apply from ADB".

# (7) Sideload your built zip. The OTA's update_engine will write all 21
#     partitions (system/vendor/product/system_ext/boot/dtbo PLUS modem,
#     lk, gz, scp, sspm, tee, audio_dsp, cam_vpu*, vbmeta*).
adb -d sideload out/target/product/rosemary/lineage-*-UNOFFICIAL-rosemary.zip

# (8) Reboot to system. First boot may take 3–5 minutes (dexopt + zygote warmup).
#     If it sits on the LineageOS logo for >10 min, hold power 12 s, reboot to
#     recovery, and check the post-install log via "Advanced → View logs".
```

### Pre-built signed alternatives — if you don't want to flash a test-key build

If the AVB-disable step or the test-key OTA constraint bothers you, consider sideloading one of the **release-signed community builds** instead. They share the same surblazer device tree your local build is based on, ship firmware the same way, and don't need `--disable-verification`:

- **LineageOS 23.2 OFFICIAL** — built and signed by maintainer [@surblazer](https://t.me/surblazer); downloads at [download.lineageos.org/devices/rosemary/builds](https://download.lineageos.org/devices/rosemary/builds). Note in the maintainer's release post: "Firmware included". This is the reference build to compare your local one against.
- [LineageOS Extended](https://sourceforge.net/projects/mnzzprjkt/files/LineageOS-Ext/16/), [Evolution-X](https://sourceforge.net/projects/mnzzprjkt/files/Evolution-X/16/), [Lunaris-AOSP](https://sourceforge.net/projects/mnzzprjkt/files/Lunaris-AOSP/16/) — all maintained by @Mnskkyy, signed, "Firmware included", SELinux enforcing.
- [crDroid 12.7 for rosemary](https://crdroid.net/rosemary) — Android 16 QPR2, "Firmware included", vanilla (flash NikGapps / microG separately for Play services).
- Community discovery: [@RedmiNote10SIDUpdate Telegram channel](https://t.me/RedmiNote10SIDUpdate) (Indonesian RN10S community) is the most active publication channel for rosemary builds across all distros — newer drops show up here first.

The install sequence above is unchanged for these (skip step 2 since they're release-signed).

### Safety net — recovering from a bad flash

In rough order of severity:

- **Boots into "your device's bootloader is unlocked" then loops back** → AVB still enforced. Repeat step (2) in the install sequence.
- **Boots straight to recovery (no OS)** → almost always a wiped `/data` from step (6) plus a sideload that didn't finish writing system. Re-sideload the zip.
- **Stuck on LineageOS logo forever** → most often a dtbo/boot version skew. Re-flash *Lineage's own* boot.img and dtbo.img (step 3 + 4) to both slots, then re-sideload.
- **No cellular signal after a successful boot** → `md1img` didn't write (rare, but happens if you sideloaded a zip without firmware partitions). Verify with §4 step 5; if missing, you need a different zip. Worst case, flash the TFF MIUI tgz's `md1img_a` / `md1img_b` and reboot.
- **Soft brick (won't enter fastboot)** → hold Vol-Down + Power for ~12 s to force-enter fastboot. From there, fastboot-flash the TFF MIUI tgz's `boot.img` / `dtbo.img` / `vbmeta.img` to get back to MIUI's recovery, then `MiFlash → Clean all` to fully revert.
- **Hard brick (only "MediaTek USB Port" enumerates, no fastboot)** → BROM-mode rescue with **SP Flash Tool v5.2208** + MTK USB drivers + the TFF scatter file. Canonical writeup: [XDA — Rosemary SP Flash Tool BROM dead-boot fix](https://xdaforums.com/t/rosemary-redmi-note-10s-flashing-with-sp-flash-tool-in-brom-mode-dead-boot-fix-added.4599693/). This works for all five variants because BROM sits below the variant-aware preloader.

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
