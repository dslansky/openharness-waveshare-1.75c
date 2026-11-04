#!/usr/bin/env bash
# Clone upstream openharness at the pinned commit and apply this repo's patches.
#
#   scripts/setup.sh            # clone into ./work/openharness and apply patches
#   scripts/setup.sh --build    # same, then build the firmware (needs ESP-IDF 5.5.4 activated)
set -euo pipefail

here="$(cd "$(dirname "$0")/.." && pwd)"
commit="$(tr -d '[:space:]' < "$here/UPSTREAM_COMMIT")"
work="$here/work/openharness"

if [ ! -d "$work/.git" ]; then
  mkdir -p "$here/work"
  git clone --filter=blob:none https://github.com/autonomous-ai/openharness.git "$work"
fi

cd "$work"
git fetch -q origin "$commit" 2>/dev/null || true
git checkout -q -B waveshare-1.75c "$commit"
for p in "$here"/patches/*.patch; do
  echo "applying $(basename "$p")"
  git -c user.name=overlay -c user.email=overlay@localhost am -q --committer-date-is-author-date "$p"
done
echo "upstream $commit + $(ls "$here"/patches/*.patch | wc -l | tr -d ' ') patch(es) ready in $work"

if [ "${1:-}" = "--build" ]; then
  command -v idf.py >/dev/null || { echo "idf.py not found: activate ESP-IDF 5.5.4 first (. ~/esp/esp-idf-v5.5.4/export.sh)"; exit 1; }
  cd devices/harness-device/firmware
  idf.py set-target esp32s3
  idf.py build
fi
