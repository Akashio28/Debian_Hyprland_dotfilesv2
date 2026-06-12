#!/bin/bash
# ~/.config/hypr/scripts/menu-simple.sh

# Style untuk rofi
ROFI_STYLE=(
    -theme-str 'window {border: 2px; border-color: #cba6f7; border-radius: 12px; padding: 20px; background-color: #1e1e2e;}'
    -theme-str 'textbox {horizontal-align: 0.5; text-color: #cdd6f4; font: "Inter 12";}'
    -theme-str 'listview {lines: 6; spacing: 5px;}'
    -theme-str 'element {padding: 10px; border-radius: 6px; background-color: #313244; text-color: #cdd6f4;}'
    -theme-str 'element selected {background-color: #cba6f7; text-color: #1e1e2e; font-weight: bold;}'
)

# Menu utama
chosen=$(echo -e "Power Off\nRestart\nLogout\nLock\nSuspend\nCancel" | \
    rofi -dmenu "${ROFI_STYLE[@]}" \
        -p "⚡ Power Menu" \
        -lines 6 \
        -width 250 \
        -location 0)

# Style untuk konfirmasi (lebih kecil)
CONFIRM_STYLE=(
    -theme-str 'window {border: 1px; border-color: #cba6f7; border-radius: 10px; padding: 15px;}'
    -theme-str 'listview {lines: 2;}'
    -theme-str 'element {padding: 8px;}'
    -theme-str 'element selected {background-color: #cba6f7; color: #1e1e2e;}'  # TAMBAHKAN INI
)

# Fungsi konfirmasi
confirm_action() {
    local action="$1"
    confirm=$(echo -e "Yes\nNo" | \
        rofi -dmenu "${CONFIRM_STYLE[@]}" \
            -p "Are you sure to $action?" \
            -lines 2 \
            -width 200)
    [ "$confirm" = "Yes" ] && return 0 || return 1
}

# ========== EKSEKUSI LENGKAP ==========
case "$chosen" in
    "Power Off")
        if confirm_action "shutdown"; then
            systemctl poweroff
        fi
        ;;
    
    "Restart")
        if confirm_action "restart"; then
            systemctl reboot
        fi
        ;;
    
    "Logout")
        if confirm_action "logout"; then
            hyprctl dispatch exit
        fi
        ;;
    
    "Lock")
        # Lock screen langsung tanpa konfirmasi
        swaylock
        ;;
    
    "Suspend")
        if confirm_action "suspend"; then
            systemctl suspend
        fi
        ;;
    
    *)
        # Cancel atau pilihan lain
        exit 0
        ;;
esac
