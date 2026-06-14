#!/bin/bash

# /* ---- 💫 https://github.com/Akashio28 💫 ---- */
# Akashio's Debian Hyprland Dotfiles v2 - Install Script

clear

# Colors
OK="$(tput setaf 2)[OK]$(tput sgr0)"
ERROR="$(tput setaf 1)[ERROR]$(tput sgr0)"
NOTE="$(tput setaf 3)[NOTE]$(tput sgr0)"
INFO="$(tput setaf 4)[INFO]$(tput sgr0)"
WARN="$(tput setaf 1)[WARN]$(tput sgr0)"
CAT="$(tput setaf 6)[ACTION]$(tput sgr0)"
MAGENTA="$(tput setaf 5)"
YELLOW="$(tput setaf 3)"
GREEN="$(tput setaf 2)"
BLUE="$(tput setaf 4)"
SKY_BLUE="$(tput setaf 6)"
RESET="$(tput sgr0)"

# Banner
printf "\n"
echo -e "\e[35m"
cat << "EOF"
    ___    __            __    _     
   /   |  / /______ _  / /_  (_)___ 
  / /| | / //_/ __ `/ / __ \/ / __ \
 / ___ |/ ,< / /_/ / / / / / / /_/ /
/_/  |_/_/|_|\__,_/ /_/ /_/_/\____/ 
                                     
  Debian Hyprland Dotfiles v2
  https://github.com/Akashio28/Debian_Hyprland_dotfilesv2
EOF
echo -e "\e[0m"
printf "\n"

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    echo "${ERROR} Do NOT run this script as root or with sudo!" 
    echo "${NOTE} Run as a normal user. The script will call sudo when needed."
    exit 1
fi

# Check if running on Debian/apt-based
if ! command -v apt &>/dev/null; then
    echo "${ERROR} This script only supports Debian-based systems (apt required)."
    exit 1
fi

# Confirm to proceed
echo "${NOTE} This script will:"
echo "  1. Update your system"
echo "  2. Install Hyprland & all required packages"
echo "  3. Backup your existing configs (if any)"
echo "  4. Copy dotfiles to ~/.config"
echo "  5. Install hyprpm plugins"
printf "\n"
read -rp "${CAT} Do you want to continue? [y/N]: " confirm
case "$confirm" in
    [yY][eE][sS]|[yY]) 
        echo "${OK} Starting installation..."
        ;;
    *)
        echo "${NOTE} Installation cancelled. Goodbye!"
        exit 0
        ;;
esac

# Create log directory
mkdir -p Install-Logs
LOG="Install-Logs/install-$(date +%d-%H%M%S).log"

printf "\n"
echo "${INFO} Log file: $LOG"
printf "\n"

# ─────────────────────────────────────────────
# 1. System Update
# ─────────────────────────────────────────────
echo "${INFO} Updating system..." | tee -a "$LOG"
sudo apt update && sudo apt upgrade -y 2>&1 | tee -a "$LOG"
echo "${OK} System updated." | tee -a "$LOG"
printf "\n"

# ─────────────────────────────────────────────
# 2. Install Required Packages
# ─────────────────────────────────────────────
echo "${INFO} Installing required packages..." | tee -a "$LOG"

PACKAGES=(
    # Core
    hyprland
    hyprlock
    hypridle
    waybar
    rofi
    swaync
    kitty
    thunar
    swww
    # Fonts
    fonts-noto
    fonts-noto-color-emoji
    fonts-jetbrains-mono
    # Tools
    wlogout
    wofi
    tofi
    btop
    cava
    fastfetch
    grim
    slurp
    swappy
    wl-clipboard
    cliphist
    brightnessctl
    pamixer
    playerctl
    network-manager
    nm-applet
    blueman
    polkit-kde-agent-1
    xdg-desktop-portal-hyprland
    xdg-utils
    qt5ct
    qt6ct
    nwg-look
    # Wallpaper
    wallust
)

for pkg in "${PACKAGES[@]}"; do
    if ! dpkg -l | grep -q "^ii.*$pkg"; then
        echo "${INFO} Installing $pkg..." | tee -a "$LOG"
        sudo apt install -y "$pkg" 2>&1 | tee -a "$LOG" || echo "${WARN} Failed to install $pkg (may not be in repo)" | tee -a "$LOG"
    else
        echo "${OK} $pkg already installed." | tee -a "$LOG"
    fi
done

printf "\n"
echo "${OK} Packages installed." | tee -a "$LOG"

# ─────────────────────────────────────────────
# 3. Backup Existing Configs
# ─────────────────────────────────────────────
BACKUP_DIR="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"
CONFIG_DIRS=(hypr waybar rofi kitty swaync wlogout wofi tofi btop cava wallust nwg-look)

echo "${INFO} Checking for existing configs to backup..." | tee -a "$LOG"

for dir in "${CONFIG_DIRS[@]}"; do
    if [ -d "$HOME/.config/$dir" ]; then
        mkdir -p "$BACKUP_DIR"
        mv "$HOME/.config/$dir" "$BACKUP_DIR/$dir"
        echo "${NOTE} Backed up ~/.config/$dir → $BACKUP_DIR/$dir" | tee -a "$LOG"
    fi
done

if [ -d "$BACKUP_DIR" ]; then
    echo "${OK} Old configs backed up to: $BACKUP_DIR" | tee -a "$LOG"
else
    echo "${OK} No existing configs found. Skipping backup." | tee -a "$LOG"
fi

printf "\n"

# ─────────────────────────────────────────────
# 4. Copy Dotfiles
# ─────────────────────────────────────────────
echo "${INFO} Copying dotfiles to ~/.config..." | tee -a "$LOG"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

for dir in "${CONFIG_DIRS[@]}"; do
    if [ -d "$SCRIPT_DIR/$dir" ]; then
        cp -r "$SCRIPT_DIR/$dir" "$HOME/.config/"
        echo "${OK} Copied $dir" | tee -a "$LOG"
    else
        echo "${WARN} $dir not found in repo, skipping..." | tee -a "$LOG"
    fi
done

# Make scripts executable
find "$HOME/.config/hypr" -name "*.sh" -exec chmod +x {} \; 2>/dev/null
echo "${OK} Scripts made executable." | tee -a "$LOG"

printf "\n"

# ─────────────────────────────────────────────
# 5. Install hyprpm plugins
# ─────────────────────────────────────────────
echo "${INFO} Setting up hyprpm plugins..." | tee -a "$LOG"

if command -v hyprpm &>/dev/null; then
    hyprpm update 2>&1 | tee -a "$LOG"
    hyprpm reload -n 2>&1 | tee -a "$LOG"
    echo "${OK} hyprpm plugins configured." | tee -a "$LOG"
else
    echo "${WARN} hyprpm not found. Skipping plugin setup." | tee -a "$LOG"
fi

printf "\n"

# ─────────────────────────────────────────────
# Done!
# ─────────────────────────────────────────────
echo -e "${GREEN}"
cat << "EOF"
╔══════════════════════════════════════════╗
║   Installation Complete! 🎉              ║
║                                          ║
║   Next steps:                            ║
║   1. Reboot your system                  ║
║   2. Select Hyprland from login manager  ║
║   3. Press SUPER + H for keybind help    ║
╚══════════════════════════════════════════╝
EOF
echo -e "${RESET}"

if [ -d "$BACKUP_DIR" ]; then
    echo "${NOTE} Your old configs were backed up to: $BACKUP_DIR"
fi

echo "${NOTE} Install log saved to: $LOG"
printf "\n"

read -rp "${CAT} Would you like to reboot now? [y/N]: " reboot_confirm
case "$reboot_confirm" in
    [yY][eE][sS]|[yY])
        echo "${INFO} Rebooting..."
        systemctl reboot
        ;;
    *)
        echo "${OK} Done! Please reboot manually when ready."
        ;;
esac
