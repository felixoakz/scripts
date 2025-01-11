#!/bin/bash

# Define colors and symbols
COLOR_RESET="\033[0m"
COLOR_GREEN="\033[32m"
COLOR_RED="\033[31m"
COLOR_YELLOW="\033[33m"
ARROW="---> "

# Function to print colored messages
print_message() {
  local color=$1
  local message=$2
  echo -e "${color}${ARROW}${message}${COLOR_RESET}"
}

# Install yay if not already installed
if ! command -v yay &>/dev/null; then
  print_message "$COLOR_YELLOW" "yay not found, installing yay..."
  sudo pacman -S --needed git base-devel || { print_message "$COLOR_RED" "Failed to install required packages for yay."; exit 1; }
  git clone https://aur.archlinux.org/yay.git || { print_message "$COLOR_RED" "Failed to clone yay repository."; exit 1; }
  cd yay
  makepkg -si || { print_message "$COLOR_RED" "Failed to build and install yay."; exit 1; }
  cd ..
fi

# Function to check if a package is available in the repositories or AUR
is_package_available() {
  local package=$1
  # Check if the package is available in the official repositories
  pacman -Qi "$package" &>/dev/null || yay -Qi "$package" &>/dev/null
}

# Function to install a package
install_package() {
  local package=$1
  if is_package_available "$package"; then
    print_message "$COLOR_GREEN" "$package is available in the repositories or AUR."
  else
    print_message "$COLOR_YELLOW" "$package not found. Installing with yay..."
    yay -S --noconfirm "$package" || { print_message "$COLOR_RED" "Failed to install $package with yay."; exit 1; }
  fi
}

# List of packages to install
packages=(
  # Shells
  "zsh"

  # System utilities
  "neovim"
  "lazygit"
  "tmux"
  "neofetch"
  "stow"
  "blueman"
  "systemd-homed"
  "gnome-disk-utility"
  "gnome-system-monitor"
  "catppuccin-gtk-theme-mocha"
  "nwg-look"
  "nautilus"
  "fragments"

  # Graphics and display
  "hyprland"
  "wayland"
  "wayland-protocols"
  "wlroots"
  "xorg-xwayland"
  "qt5-wayland"
  "qt6-wayland"
  "wofi"
  "swappy"
  "xdg-desktop-portal-gtk"

  # Fonts
  "ttf-dejavu"
  "ttf-freefont"
  "fontconfig"
  "noto-fonts"
  "ttf-hack"
  "ttf-material-design-icons"
  "ttf-font-awesome"

  # Networking
  "networkmanager"
  "network-manager-applet"
  "xorg-server-xwayland"

  # Audio and video
  "pavucontrol"
  "pulseaudio"
  "playerctl"
  "pipewire"
  "pipewire-alsa"
  "pipewire-pulse"
  "pipewire-jack"

  # NVIDIA drivers
  'nvidia'
  'nvidia-utils'
  'nvidia-settings'

  # Other
  "polkit-gnome"
  "wl-clipboard"
  "kitty"
  "yazi"
  "python-pillow"
  "xdg-desktop-portal-hyprland-git"
  "ripgrep"

  # Development tools
  "insomnia"
  "nodejs"
  "npm"
  "nvm"
  "python"
  "python-pip"
  "docker"
  "docker-compose"
  "php"
  "sqlite"
  "laravel"
  "composer"
  "datagrip"
  "jre-openjdk"
  "android-studio"
)

# Install packages
for package in "${packages[@]}"; do
  install_package "$package"
done

# Clone and stow dotfiles if not already present
if [ ! -d "dotfiles" ]; then
  print_message "$COLOR_YELLOW" "Cloning dotfiles repository..."
  git clone https://github.com/felixoakz/dotfiles.git || { print_message "$COLOR_RED" "Failed to clone dotfiles repository."; exit 1; }
fi

print_message "$COLOR_YELLOW" "Stowing dotfiles..."
cd dotfiles
stow . || { print_message "$COLOR_RED" "Failed to stow dotfiles."; exit 1; }
cd ..

# Change default shell to zsh
print_message "$COLOR_YELLOW" "Changing default shell to zsh..."
chsh -s "$(which zsh)" || { print_message "$COLOR_RED" "Failed to change default shell to zsh."; exit 1; }

print_message "$COLOR_GREEN" "Installation complete."
