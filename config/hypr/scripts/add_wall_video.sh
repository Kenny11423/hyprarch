#!/usr/bin/env bash
set -euo pipefail

CONFIG_DIR="${HOME}/.config/hypr"
VIDEO_JSON="${CONFIG_DIR}/video_wallpapers.json"
CACHE_DIR="${HOME}/.cache/rofi_icons"
ROFI_IMG_DIR="${HOME}/.cache/rofi"
ENGINE_EXEC="linux-wallpaperengine"

if ! command -v "${ENGINE_EXEC}" >/dev/null 2>&1; then
  notify-send "Wallpaper Engine Error" "linux-wallpaperengine is not installed on the system!" 2>/dev/null || true
  exit 1
fi

mkdir -p "${CONFIG_DIR}" "${CACHE_DIR}" "${ROFI_IMG_DIR}"

FORM_OUT=$(yad --form --title="Add Video Wallpaper Engine" \
  --width=480 --height=260 --center \
  --window-icon="video-display" \
  --field="Wallpaper Engine ID:":TEXT "" \
  --field="Wallpaper Name:":TEXT "" \
  --field="Preview Image File:":FL "" \
  --file-filter="Images | *.jpg *.png *.jpeg *.webp *.gif" 2>/dev/null || true)

if [ -z "$FORM_OUT" ]; then
  exit 0
fi

IFS="|" read -r W_ID W_NAME PREVIEW_IMG <<< "$FORM_OUT"

W_ID=$(echo "$W_ID" | xargs)
W_NAME=$(echo "$W_NAME" | xargs)
PREVIEW_IMG=$(echo "$PREVIEW_IMG" | xargs)

if [ -z "$W_ID" ]; then
  notify-send "Error" "Wallpaper Engine ID cannot be empty!" 2>/dev/null || true
  exit 1
fi

if [ -z "$W_NAME" ]; then
  W_NAME="Wallpaper ${W_ID}"
fi

THUMB_PATH="${CACHE_DIR}/video_${W_ID}.jpg"
if [ -n "$PREVIEW_IMG" ] && [ -f "$PREVIEW_IMG" ]; then
  magick "${PREVIEW_IMG}[0]" -resize 300x300^ -gravity center -extent 300x300 "$THUMB_PATH" 2>/dev/null || true
else
  magick -size 300x300 xc:"#1b1e25" -fill "#86afef" -pointsize 30 -gravity center -draw "text 0,0 'VIDEO\n${W_ID}'" "$THUMB_PATH" 2>/dev/null || true
fi

python3 -c '
import json, os, sys
json_path = os.path.expanduser("'"${VIDEO_JSON}"'")
w_id, name, thumb = sys.argv[1], sys.argv[2], sys.argv[3]

data = []
if os.path.exists(json_path):
    try:
        with open(json_path, "r") as f:
            data = json.load(f)
    except Exception:
        data = []

found = False
for item in data:
    if item.get("id") == w_id:
        item["name"] = name
        item["thumbnail"] = thumb
        found = True
        break

if not found:
    data.append({"id": w_id, "name": name, "thumbnail": thumb})

with open(json_path, "w") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
' "$W_ID" "$W_NAME" "$THUMB_PATH"

MONITOR=$(hyprctl monitors 2>/dev/null | grep -E '^Monitor' | head -n 1 | awk '{print $2}' || echo "eDP-1")
[ -z "$MONITOR" ] && MONITOR="eDP-1"

pkill -f "linux-wallpaperengine" 2>/dev/null || true
"${ENGINE_EXEC}" --screen-root "$MONITOR" --bg "$W_ID" --scaling fill --clamp border -s >/dev/null 2>&1 &
echo "video:${W_ID}" > "${HOME}/Wallpapers/wallpaper_tracking.txt" 2>/dev/null || true

if [ -f "$THUMB_PATH" ]; then
  mkdir -p "${ROFI_IMG_DIR}"
  sed -i "s#background-image:.*#background-image: url(\"${THUMB_PATH}\",width);#" "${ROFI_IMG_DIR}/img_path.rasi" 2>/dev/null || true
fi
