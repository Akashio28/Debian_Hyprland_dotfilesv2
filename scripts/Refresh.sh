#!/bin/bash
# Simple refresh script for waybar

# Kill waybar dengan paksa
pkill -f waybar
sleep 1

# Jalankan waybar lagi
waybar &

# Notifikasi
notify-send "Waybar Refreshed" "Warna diperbarui sesuai wallpaper"

exit 0
