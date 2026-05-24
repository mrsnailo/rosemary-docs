#!/usr/bin/env bash
#
# apply.sh — apply rosemary ROM patches to a LineageOS source tree.
#
# Patches live at patches/<branch>/<project-path>/*.patch where
# <project-path> matches the path of the target project inside the
# LineageOS tree (e.g. tools/extract-utils, device/xiaomi/rosemary,
# kernel/xiaomi/mt6785, frameworks/base).
#
# Usage:
#   ./apply.sh [--tree DIR] [--branch BRANCH] [--dry-run] [--reverse]
#
# Defaults:
#   --tree   = $ANDROID_BUILD_TOP if set, else ~/android/lineage
#   --branch = lineage-23.2
#
# Idempotent: already-applied patches are skipped. Run this after every
# `repo sync` to re-apply local modifications.

set -euo pipefail

TREE="${ANDROID_BUILD_TOP:-$HOME/android/lineage}"
BRANCH="lineage-23.2"
DRY_RUN=0
REVERSE=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --tree) TREE="$2"; shift 2 ;;
        --branch) BRANCH="$2"; shift 2 ;;
        --dry-run) DRY_RUN=1; shift ;;
        --reverse) REVERSE=1; shift ;;
        -h|--help) sed -n '3,18p' "$0"; exit 0 ;;
        *) echo "unknown arg: $1" >&2; exit 1 ;;
    esac
done

PATCHES_DIR="$(cd "$(dirname "$0")" && pwd)/$BRANCH"

if [[ ! -d "$PATCHES_DIR" ]]; then
    echo "No patches at $PATCHES_DIR — nothing to do."
    exit 0
fi

if [[ ! -d "$TREE" ]]; then
    echo "Error: LineageOS tree not found at $TREE" >&2
    echo "       Run 'repo init' + 'repo sync' first, or pass --tree DIR." >&2
    exit 1
fi

applied=0; skipped=0; failed=0

while IFS= read -r patch; do
    rel="${patch#$PATCHES_DIR/}"
    project="${rel%/*}"
    target_dir="$TREE/$project"
    pname="$project/$(basename "$patch")"

    if [[ ! -d "$target_dir/.git" ]]; then
        echo "  SKIP (no git project at $project): $pname" >&2
        skipped=$((skipped+1))
        continue
    fi

    cd "$target_dir"

    if [[ "$REVERSE" == 1 ]]; then
        if git apply --check --reverse "$patch" 2>/dev/null; then
            if [[ "$DRY_RUN" == 1 ]]; then
                echo "  would reverse: $pname"
            else
                git apply --reverse "$patch"
                echo "  REVERSED: $pname"
            fi
            applied=$((applied+1))
        else
            echo "  SKIP (not currently applied): $pname"
            skipped=$((skipped+1))
        fi
        continue
    fi

    if git apply --check --reverse "$patch" 2>/dev/null; then
        echo "  SKIP (already applied): $pname"
        skipped=$((skipped+1))
        continue
    fi

    if ! git apply --check "$patch" 2>/dev/null; then
        echo "  FAIL (would not apply cleanly): $pname" >&2
        failed=$((failed+1))
        continue
    fi

    if [[ "$DRY_RUN" == 1 ]]; then
        echo "  would apply: $pname"
    else
        git apply "$patch"
        echo "  APPLIED: $pname"
    fi
    applied=$((applied+1))
done < <(find "$PATCHES_DIR" -name '*.patch' -type f | sort)

echo
echo "Summary: applied=$applied skipped=$skipped failed=$failed"
[[ $failed -eq 0 ]] || exit 1
