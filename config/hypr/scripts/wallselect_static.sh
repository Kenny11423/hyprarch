#!/usr/bin/env bash
set -euo pipefail

WALL_DIR="${HOME}/Wallpapers"
CACHE_DIR="${HOME}/.cache/rofi_icons"
ROFI_IMG_DIR="${HOME}/.cache/rofi"

mkdir -p "${WALL_DIR}" "${CACHE_DIR}" "${ROFI_IMG_DIR}"

for imagen in "$WALL_DIR"/*.{jpg,jpeg,png,webp,gif}; do
  [ -f "$imagen" ] || continue
  nombre_archivo=$(basename "$imagen")
  if [ ! -f "${CACHE_DIR}/${nombre_archivo}" ]; then
    magick "${imagen}[0]" -resize 300x300^ -gravity center -extent 300x300 "${CACHE_DIR}/${nombre_archivo}" 2>/dev/null || true
  fi
done

if [ $# -eq 0 ]; then
  find "${WALL_DIR}" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.gif" \) -exec basename {} \; | sort | while read -r img; do
    echo -en "${img}\0icon\x1f${CACHE_DIR}/${img}\n"
  done
  exit 0
fi

SELECTION="$1"
BASENAME=$(basename "$SELECTION")

if [ -f "${WALL_DIR}/${BASENAME}" ]; then
  pkill -f "linux-wallpaperengine" 2>/dev/null || true
  awww query >/dev/null 2>&1 || awww init
  awww img "${WALL_DIR}/${BASENAME}" --transition-bezier .43,1.19,1,.4 --transition-fps 144 --transition-type grow --transition-duration 2 --transition-pos 0.680,0.970

  echo "$BASENAME" > "${WALL_DIR}/wallpaper_tracking.txt" 2>/dev/null || true
  mkdir -p "${ROFI_IMG_DIR}"
  sed -i "s#background-image:.*#background-image: url(\"${WALL_DIR}/${BASENAME}\",width);#" "${ROFI_IMG_DIR}/img_path.rasi" 2>/dev/null || true
fi
