#!/usr/bin/env bash
set -e

WALL_DIR="/home/kennysk/Wallpapers"

# đảm bảo swww đang chạy
swww query >/dev/null 2>&1 || swww init
sleep 0.5

# chọn ảnh random
WALLPAPER=$(find "$WALL_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) | shuf -n 1)

# nếu không có ảnh
[ -z "$WALLPAPER" ] && exit 0

# set wallpaper
swww img "$WALLPAPER" \
  --transition-type grow \
  --transition-duration 1

