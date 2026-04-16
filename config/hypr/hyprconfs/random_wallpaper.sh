#!/usr/bin/env bash

set -e

WALL_DIR="$HOME/Wallpapers"
CACHE_DIR="$HOME/.cache/awww"

# đảm bảo cache tồn tại
mkdir -p "$CACHE_DIR"

# nếu daemon chết hoặc chưa chạy → restart sạch
if ! pgrep -x awww-daemon >/dev/null; then
  pkill awww-daemon 2>/dev/null || true
  rm -rf "$CACHE_DIR"/*
  
  awww-daemon >/dev/null 2>&1 &
  sleep 1
fi

# chọn ảnh random
WALLPAPER=$(find "$WALL_DIR" -type f \( \
  -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.gif" \
\) | shuf -n 1)

# nếu không có ảnh thì thoát
[ -z "$WALLPAPER" ] && exit 0

# set wallpaper (fallback nếu transition lỗi)
awww img "$WALLPAPER" \
  --transition-type grow \
  --transition-duration 1 \
  || awww img "$WALLPAPER"