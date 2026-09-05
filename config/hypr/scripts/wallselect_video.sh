#!/usr/bin/env bash
set -euo pipefail

CONFIG_DIR="${HOME}/.config/hypr"
VIDEO_JSON="${CONFIG_DIR}/video_wallpapers.json"
CACHE_DIR="${HOME}/.cache/rofi_icons"
ROFI_IMG_DIR="${HOME}/.cache/rofi"
ENGINE_EXEC="linux-wallpaperengine"
ADD_ICON="${CACHE_DIR}/add_wallpaper.png"

mkdir -p "${CONFIG_DIR}" "${CACHE_DIR}" "${ROFI_IMG_DIR}"

if [ ! -f "${VIDEO_JSON}" ]; then
  echo "[]" > "${VIDEO_JSON}"
fi

if [ ! -f "${ADD_ICON}" ]; then
  magick -size 300x300 xc:"#232b39" -fill "#86afef" -pointsize 120 -gravity center -draw "text 0,0 '+'" "${ADD_ICON}" 2>/dev/null || true
fi

if [ $# -eq 0 ]; then
  echo -en "+ Add Video Wallpaper\0icon\x1f${ADD_ICON}\n"
  python3 -c '
import json, os
json_path = os.path.expanduser("'"${VIDEO_JSON}"'")
cache_dir = os.path.expanduser("'"${CACHE_DIR}"'")
add_icon = os.path.expanduser("'"${ADD_ICON}"'")

if os.path.exists(json_path):
    with open(json_path, "r") as f:
        try:
            data = json.load(f)
            for item in data:
                name = item.get("name", "Untitled")
                w_id = item.get("id", "")
                icon = item.get("thumbnail", add_icon)
                if not os.path.exists(icon):
                    icon = add_icon
                title = f"{name} [ID: {w_id}]"
                print(f"{title}\0icon\x1f{icon}")
        except Exception:
            pass
'
  exit 0
fi

SELECTION="$1"

if [ "$SELECTION" = "+ Add Video Wallpaper" ]; then
  if ! command -v "${ENGINE_EXEC}" >/dev/null 2>&1; then
    notify-send "Wallpaper Engine Error" "linux-wallpaperengine is not installed on the system!" 2>/dev/null || true
    exit 1
  fi
  hyprctl dispatch exec "${HOME}/.config/hypr/scripts/add_wall_video.sh" 2>/dev/null || "${HOME}/.config/hypr/scripts/add_wall_video.sh" &
  exit 0
fi

SELECTED_ID=$(echo "$SELECTION" | grep -oE '\[ID: [^]]+\]' | sed 's/\[ID: //;s/\]//' || echo "")
if [ -z "$SELECTED_ID" ]; then
  SELECTED_ID="$SELECTION"
fi

if [ -n "$SELECTED_ID" ]; then
  if ! command -v "${ENGINE_EXEC}" >/dev/null 2>&1; then
    notify-send "Wallpaper Engine Error" "linux-wallpaperengine is not installed on the system!" 2>/dev/null || true
    exit 1
  fi

  MONITOR=$(hyprctl monitors 2>/dev/null | grep -E '^Monitor' | head -n 1 | awk '{print $2}' || echo "eDP-1")
  [ -z "$MONITOR" ] && MONITOR="eDP-1"

  pkill -f "linux-wallpaperengine" 2>/dev/null || true

  "${ENGINE_EXEC}" --screen-root "$MONITOR" --bg "$SELECTED_ID" --scaling fill --clamp border -s >/dev/null 2>&1 &

  echo "video:${SELECTED_ID}" > "${HOME}/Wallpapers/wallpaper_tracking.txt" 2>/dev/null || true
  
  THUMB_PATH="${CACHE_DIR}/video_${SELECTED_ID}.jpg"
  if [ -f "$THUMB_PATH" ]; then
    mkdir -p "${ROFI_IMG_DIR}"
    sed -i "s#background-image:.*#background-image: url(\"${THUMB_PATH}\",width);#" "${ROFI_IMG_DIR}/img_path.rasi" 2>/dev/null || true
  fi
fi
