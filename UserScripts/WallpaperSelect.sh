#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */
# This script for selecting wallpapers (SUPER W)

# WALLPAPERS PATH
terminal=kitty
wallDIR="$HOME/Pictures/wallpapers"
SCRIPTSDIR="$HOME/.config/hypr/scripts"
wallpaper_current="$HOME/.config/hypr/wallpaper_effects/.wallpaper_current"

# Directory for swaync
iDIR="$HOME/.config/swaync/images"
iDIRi="$HOME/.config/swaync/icons"

# swww transition config
FPS=60
TYPE="any"
DURATION=0.2
BEZIER=".43,1.19,1,.4"
SWWW_PARAMS="--transition-fps $FPS --transition-type $TYPE --transition-duration $DURATION --transition-bezier $BEZIER"

# Check if required packages exist
if ! command -v bc &>/dev/null; then
  notify-send -i "$iDIR/error.png" "bc missing" "Install package bc first"
  exit 1
fi

if ! command -v jq &>/dev/null; then
  notify-send -i "$iDIR/error.png" "jq missing" "Install package jq first"
  exit 1
fi

# Variables
rofi_theme="$HOME/.config/rofi/config-wallpaper.rasi"
focused_monitor=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')

# Ensure focused_monitor is detected
if [[ -z "$focused_monitor" ]]; then
  notify-send -i "$iDIR/error.png" "E-R-R-O-R" "Could not detect focused monitor"
  exit 1
fi

# Monitor details
scale_factor=$(hyprctl monitors -j | jq -r --arg mon "$focused_monitor" '.[] | select(.name == $mon) | .scale')
monitor_height=$(hyprctl monitors -j | jq -r --arg mon "$focused_monitor" '.[] | select(.name == $mon) | .height')

icon_size=$(echo "scale=1; ($monitor_height * 3) / ($scale_factor * 150)" | bc)
adjusted_icon_size=$(echo "$icon_size" | awk '{if ($1 < 15) $1 = 20; if ($1 > 25) $1 = 25; print $1}')
rofi_override="element-icon{size:${adjusted_icon_size}%;}"

# Kill existing wallpaper daemons
kill_wallpaper_daemons() {
  swww kill 2>/dev/null
  pkill mpvpaper 2>/dev/null
  pkill swaybg 2>/dev/null
  pkill hyprpaper 2>/dev/null
}

# Retrieve wallpapers (both images & videos)
mapfile -d '' PICS < <(find -L "${wallDIR}" -type f \( \
  -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o \
  -iname "*.bmp" -o -iname "*.tiff" -o -iname "*.webp" -o \
  -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.mov" -o -iname "*.webm" \) -print0 2>/dev/null)

# Check if any wallpapers found
if [ ${#PICS[@]} -eq 0 ]; then
  notify-send -i "$iDIR/error.png" "No Wallpapers" "No wallpapers found in $wallDIR"
  exit 1
fi

RANDOM_PIC="${PICS[$((RANDOM % ${#PICS[@]}))]}"
RANDOM_PIC_NAME=".random"

# Rofi command
rofi_command="rofi -i -show -dmenu -config $rofi_theme -theme-str $rofi_override"

# Sorting Wallpapers
menu() {
  # Sort the array
  IFS=$'\n' sorted_options=($(sort <<<"${PICS[*]}"))
  
  # Print random option first
  printf "%s\x00icon\x1f%s\n" "$RANDOM_PIC_NAME" "$RANDOM_PIC"

  # Print all wallpapers
  for pic_path in "${sorted_options[@]}"; do
    pic_name=$(basename "$pic_path")
    
    # Handle GIF files
    if [[ "$pic_name" =~ \.gif$ ]]; then
      cache_gif_image="$HOME/.cache/gif_preview/${pic_name}.png"
      if [[ ! -f "$cache_gif_image" ]]; then
        mkdir -p "$HOME/.cache/gif_preview"
        if command -v magick &>/dev/null; then
          magick "$pic_path[0]" -resize 1920x1080 "$cache_gif_image" 2>/dev/null
        else
          # Fallback if ImageMagick not available
          cache_gif_image="$pic_path"
        fi
      fi
      printf "%s\x00icon\x1f%s\n" "$pic_name" "$cache_gif_image"
    
    # Handle video files
    elif [[ "$pic_name" =~ \.(mp4|mkv|mov|webm|MP4|MKV|MOV|WEBM)$ ]]; then
      cache_preview_image="$HOME/.cache/video_preview/${pic_name}.png"
      if [[ ! -f "$cache_preview_image" ]] && command -v ffmpeg &>/dev/null; then
        mkdir -p "$HOME/.cache/video_preview"
        ffmpeg -v error -y -i "$pic_path" -ss 00:00:01.000 -vframes 1 "$cache_preview_image" 2>/dev/null
      fi
      if [[ -f "$cache_preview_image" ]]; then
        printf "%s\x00icon\x1f%s\n" "$pic_name" "$cache_preview_image"
      else
        printf "%s\n" "$pic_name"
      fi
    
    # Handle image files
    else
      # Use actual image as icon
      printf "%s\x00icon\x1f%s\n" "$(basename "$pic_name" | sed 's/\.[^.]*$//')" "$pic_path"
    fi
  done
}

# Offer SDDM Simple Wallpaper Option
set_sddm_wallpaper() {
  # Skip if it's a video wallpaper
  if [[ "$1" =~ \.(mp4|mkv|mov|webm|MP4|MKV|MOV|WEBM)$ ]]; then
    return 0
  fi
  
  sleep 1

  # Resolve SDDM themes directory
  local sddm_themes_dir=""
  if [ -d "/usr/share/sddm/themes" ]; then
    sddm_themes_dir="/usr/share/sddm/themes"
  elif [ -d "/run/current-system/sw/share/sddm/themes" ]; then
    sddm_themes_dir="/run/current-system/sw/share/sddm/themes"
  fi

  [ -z "$sddm_themes_dir" ] && return 0

  local sddm_simple="$sddm_themes_dir/simple_sddm_2"

  # Only prompt if theme exists
  if [ -d "$sddm_simple" ]; then
    
    # Check if yad is installed
    if ! command -v yad &>/dev/null; then
      return 0
    fi
    
    # Kill existing yad instances
    pkill yad 2>/dev/null

    if yad --info --text="Set current wallpaper as SDDM background?\n\nNOTE: This only applies to SIMPLE SDDM v2 Theme" \
      --text-align=left \
      --title="SDDM Background" \
      --timeout=5 \
      --timeout-indicator=right \
      --button="yes:0" \
      --button="no:1" 2>/dev/null; then

      # Check if sddm_wallpaper script exists
      if [[ -f "$SCRIPTSDIR/sddm_wallpaper.sh" ]]; then
        "$SCRIPTSDIR/sddm_wallpaper.sh" --normal
      fi
    fi
  fi
}

modify_startup_config() {
  local selected_file="$1"
  local startup_config="$HOME/.config/hypr/UserConfigs/Startup_Apps.conf"
  
  # Create directory if it doesn't exist
  mkdir -p "$(dirname "$startup_config")"
  
  # Create file if it doesn't exist
  if [[ ! -f "$startup_config" ]]; then
    touch "$startup_config"
  fi

  # Check if it's a video wallpaper
  if [[ "$selected_file" =~ \.(mp4|mkv|mov|webm|MP4|MKV|MOV|WEBM)$ ]]; then
    # Comment out swww-daemon line
    sed -i 's/^\([[:space:]]*exec-once[[:space:]]*=[[:space:]]*swww-daemon.*\)/#\1/' "$startup_config"
    
    # Uncomment mpvpaper line (if it exists)
    sed -i 's/^[#[:space:]]*\(exec-once[[:space:]]*=[[:space:]]*mpvpaper.*\)/\1/' "$startup_config"
    
    # If no mpvpaper line exists, add it
    if ! grep -q "exec-once.*mpvpaper" "$startup_config"; then
      echo "exec-once = mpvpaper '*' -o \"load-scripts=no no-audio --loop\" \"$selected_file\"" >> "$startup_config"
    else
      # Update existing mpvpaper line
      sed -i "s|^\(exec-once[[:space:]]*=[[:space:]]*mpvpaper[[:space:]]*\*[[:space:]]*-o.*\"\).*\(\"\)|\1$selected_file\2|" "$startup_config"
    fi
  else
    # For image wallpapers
    # Uncomment swww-daemon line
    sed -i 's/^#[[:space:]]*\(exec-once[[:space:]]*=[[:space:]]*swww-daemon.*\)/\1/' "$startup_config"
    
    # Comment out mpvpaper line
    sed -i 's/^\(exec-once[[:space:]]*=[[:space:]]*mpvpaper.*\)/#\1/' "$startup_config"
    
    # Add swww restore command if not exists
    if ! grep -q "swww restore" "$startup_config"; then
      echo "exec-once = swww restore" >> "$startup_config"
    fi
  fi
}

# Apply Image Wallpaper
apply_image_wallpaper() {
  local image_path="$1"
  local no_refresh="$2"

  kill_wallpaper_daemons

  # Start swww-daemon if not running
  if ! pgrep -x "swww-daemon" >/dev/null; then
    swww-daemon --format xrgb &
    sleep 1
  fi

  # Apply wallpaper
  swww img "$image_path" $SWWW_PARAMS

  # Save current wallpaper
  echo "$image_path" > "$wallpaper_current"

  # Run WallustSwww.sh if it exists
  if [[ -f "$SCRIPTSDIR/WallustSwww.sh" ]]; then
    "$SCRIPTSDIR/WallustSwww.sh" "$image_path"
  fi
  
  sleep 1

  # HANYA JALANKAN JIKA TIDAK ADA ARGUMEN --no-refresh
  if [[ "$no_refresh" != "--no-refresh" ]]; then
    if [[ -f "$SCRIPTSDIR/Refresh.sh" ]]; then
      "$SCRIPTSDIR/Refresh.sh"
    fi
  fi

  # Notify
  notify-send -i "$image_path" "Wallpaper Updated" "$(basename "$image_path")"
  
  # Ask for SDDM wallpaper (only for non-video)
  set_sddm_wallpaper "$image_path"
}

apply_video_wallpaper() {
  local video_path="$1"

  # Check if mpvpaper is installed
  if ! command -v mpvpaper &>/dev/null; then
    notify-send -i "$iDIR/error.png" "E-R-R-O-R" "mpvpaper not found"
    return 1
  fi
  
  kill_wallpaper_daemons

  # Apply video wallpaper
  mpvpaper -o "load-scripts=no no-audio loop" "$focused_monitor" "$video_path" &
  
  # Save current wallpaper
  echo "$video_path" > "$wallpaper_current"
  
  # Notify
  notify-send -i "$iDIR/video.png" "Video Wallpaper Started" "$(basename "$video_path")"
}

# Main function
main() {
  # Cek argumen --no-refresh
  NO_REFRESH=""
  if [[ "$1" == "--no-refresh" ]]; then
    NO_REFRESH="--no-refresh"
  fi

  # Kill existing rofi instances
  pkill rofi 2>/dev/null
  
  # Get user choice
  choice=$(menu | $rofi_command)
  
  # Trim whitespace
  choice=$(echo "$choice" | xargs)
  RANDOM_PIC_NAME=$(echo "$RANDOM_PIC_NAME" | xargs)

  if [[ -z "$choice" ]]; then
    exit 0
  fi

  # Handle random selection
  if [[ "$choice" == "$RANDOM_PIC_NAME" ]]; then
    selected_file="$RANDOM_PIC"
  else
    # Remove file extension from choice if present
    choice_basename=$(basename "$choice" | sed 's/\.[^.]*$//')
    
    # Find the actual file
    selected_file=$(find -L "$wallDIR" -type f -iname "${choice_basename}.*" -print -quit 2>/dev/null)
    
    if [[ -z "$selected_file" ]]; then
      # Try direct match with the full name
      selected_file=$(find -L "$wallDIR" -type f -iname "$choice" -print -quit 2>/dev/null)
    fi
  fi

  if [[ -z "$selected_file" ]]; then
    notify-send -i "$iDIR/error.png" "Error" "Selected wallpaper not found: $choice"
    exit 1
  fi

  # Modify startup config
  modify_startup_config "$selected_file"

  # Apply wallpaper based on type
  if [[ "$selected_file" =~ \.(mp4|mkv|mov|webm|MP4|MKV|MOV|WEBM)$ ]]; then
    apply_video_wallpaper "$selected_file"
  else
    apply_image_wallpaper "$selected_file" "$NO_REFRESH"
  fi
}

# Run main function with all arguments
main "$@"
