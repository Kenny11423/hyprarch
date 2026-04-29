#!/usr/bin/env bash

# Log file for debugging
LOG_FILE="/tmp/random_wallpaper.log"
# Clear old log and start new one
echo "--- Script started at $(date) ---" > "$LOG_FILE"
exec >> "$LOG_FILE" 2>&1

set -e

# Đợi một chút để hệ thống/Wayland sẵn sàng (bỏ qua nếu có tham số --now)
if [ "$1" != "--now" ]; then
  echo "Initial sleep for boot stabilization..."
  sleep 2
fi

WALL_DIR="$HOME/Wallpapers"
CACHE_DIR="$HOME/.cache/awww"

# đảm bảo cache tồn tại
mkdir -p "$CACHE_DIR"

# Kiểm tra daemon
if ! pgrep -x awww-daemon >/dev/null; then
  echo "awww-daemon not running, starting it..."
  pkill awww-daemon 2>/dev/null || true
  rm -rf "$CACHE_DIR"/*
  awww-daemon >/dev/null 2>&1 &
  sleep 2 # Đợi daemon khởi động hẳn
else
  echo "awww-daemon is already running."
  # Nếu nó vừa mới được chạy bởi Hyprland, hãy đợi thêm 1s cho chắc chắn
  sleep 1
fi

# chọn ảnh random
WALLPAPER=$(find "$WALL_DIR" -type f \( \
  -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.gif" \
\) | shuf -n 1)

# nếu không có ảnh thì thoát
if [ -z "$WALLPAPER" ]; then
  echo "No wallpaper found in $WALL_DIR"
  exit 0
fi

echo "Setting wallpaper: $WALLPAPER"

# set wallpaper
# Thử lại vài lần nếu lỗi (do daemon chưa sẵn sàng)
MAX_RETRIES=3
RETRY_COUNT=0
until awww img "$WALLPAPER" --transition-type grow --transition-duration 1 || [ $RETRY_COUNT -eq $MAX_RETRIES ]; do
  echo "Failed to set wallpaper, retrying in 1s..."
  RETRY_COUNT=$((RETRY_COUNT + 1))
  sleep 1
done

# Cập nhật tracking
echo $(basename "$WALLPAPER") > "$WALL_DIR/wallpaper_tracking.txt"
