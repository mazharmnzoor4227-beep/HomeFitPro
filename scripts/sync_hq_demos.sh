#!/usr/bin/env bash
# Copy every hq/<slug>.mp4 and hq/<slug>-start.jpg into the app assets
# without re-encoding. Mapping is already in lib/widgets/exercise_demos.dart
# (kHqDemoKeys); after a copy, rebuild the app.
set -euo pipefail
src="${1:-/workspace/GymMane-shots/hq}"
root="$(cd "$(dirname "$0")/.." && pwd)"
vid="$root/assets/demos/video"
still="$root/assets/demos/diagram"
mkdir -p "$vid" "$still"
copied=0
for f in "$src"/*.mp4; do
  [ -f "$f" ] || continue
  slug="$(basename "$f" .mp4)"
  cp -f "$f" "$vid/$slug.mp4"
  if [ -f "$src/${slug}-start.jpg" ]; then
    cp -f "$src/${slug}-start.jpg" "$still/$slug.jpg"
  fi
  copied=$((copied + 1))
  echo "synced $slug"
done
echo "copied $copied clips into $vid"
