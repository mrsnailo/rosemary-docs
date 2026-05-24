#!/usr/bin/env bash
#
# install-gallery.sh — stage the Fossify-Gallery-with-OCR fork into a
# LineageOS source tree so the next `brunch rosemary` automatically
# bundles it as a /system/app/.
#
# Usage:
#   ./install-gallery.sh [--rebuild] [--tree DIR] [--gallery DIR]
#
# Defaults:
#   --tree    = $ANDROID_BUILD_TOP if set, else ~/android/lineage
#   --gallery = $GALLERY_REPO if set, else ~/work/rosemary-gallery/upstream
#
# Idempotent: re-running is safe. The makefile injection is guarded by a
# marker comment so a follow-up `repo sync` that overwrites the device
# tree just needs another run of this script to re-apply.

set -euo pipefail

REBUILD=0
TREE="${ANDROID_BUILD_TOP:-$HOME/android/lineage}"
GALLERY_REPO="${GALLERY_REPO:-$HOME/work/rosemary-gallery/upstream}"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --rebuild) REBUILD=1; shift ;;
        --tree) TREE="$2"; shift 2 ;;
        --gallery) GALLERY_REPO="$2"; shift 2 ;;
        -h|--help)
            sed -n '3,17p' "$0"
            exit 0
            ;;
        *) echo "unknown arg: $1" >&2; exit 1 ;;
    esac
done

if [[ ! -d "$TREE" ]]; then
    echo "Error: LineageOS tree not found at $TREE" >&2
    echo "       Run 'repo init' + 'repo sync' first, or pass --tree DIR." >&2
    exit 1
fi

if [[ ! -d "$GALLERY_REPO" ]]; then
    echo "Error: gallery repo not found at $GALLERY_REPO" >&2
    echo "       Pass --gallery DIR or set GALLERY_REPO." >&2
    exit 1
fi

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ANDROID_BP_SRC="$REPO_ROOT/rom-integration/gallery/Android.bp"
APK_SRC="$GALLERY_REPO/app/build/outputs/apk/foss/debug/gallery-28-foss-debug.apk"

if [[ "$REBUILD" == 1 || ! -f "$APK_SRC" ]]; then
    echo "==> Building gallery APK in $GALLERY_REPO"
    (cd "$GALLERY_REPO" && ./gradlew :app:assembleFossDebug)
fi

if [[ ! -f "$APK_SRC" ]]; then
    echo "Error: APK not produced at $APK_SRC" >&2
    exit 1
fi

DST_DIR="$TREE/packages/apps/RosemaryGallery"
echo "==> Staging APK + Android.bp into $DST_DIR"
mkdir -p "$DST_DIR"
cp "$APK_SRC" "$DST_DIR/RosemaryGallery.apk"
cp "$ANDROID_BP_SRC" "$DST_DIR/Android.bp"

DEVICE_MK="$TREE/device/xiaomi/rosemary/lineage_rosemary.mk"
MARKER_BEGIN="# >>> ROSEMARY_GALLERY_INTEGRATION (managed by rom-integration/install-gallery.sh)"
MARKER_END="# <<< ROSEMARY_GALLERY_INTEGRATION"

if [[ ! -f "$DEVICE_MK" ]]; then
    echo "Warning: $DEVICE_MK not found — has 'breakfast rosemary' been run yet?" >&2
    echo "         APK is staged but won't be picked up until 'PRODUCT_PACKAGES += RosemaryGallery'" >&2
    echo "         lands in your rosemary device makefile. Re-run this script after breakfast." >&2
    exit 0
fi

if grep -qF "$MARKER_BEGIN" "$DEVICE_MK"; then
    echo "==> $DEVICE_MK already has the integration marker; skipping."
else
    echo "==> Adding PRODUCT_PACKAGES += RosemaryGallery to $DEVICE_MK"
    cat >> "$DEVICE_MK" <<EOF

$MARKER_BEGIN
PRODUCT_PACKAGES += \\
    RosemaryGallery
$MARKER_END
EOF
fi

echo
echo "Done. The next 'brunch rosemary' will include RosemaryGallery."
echo "To rebuild just the gallery slot without a full ROM build:"
echo "    cd \"$TREE\" && source build/envsetup.sh && unset -f grep && \\"
echo "    lunch lineage_rosemary-bp4a-userdebug && mka RosemaryGallery"
