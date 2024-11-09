#!/bin/bash

# Define log file
LOG_FILE="installation.log"

# Define colors and symbols
COLOR_RESET="\033[0m"
COLOR_GREEN="\033[32m"
COLOR_RED="\033[31m"
COLOR_YELLOW="\033[33m"
ARROW="---> "

# Redirect all script output to the log file and terminal
exec > >(tee -a "$LOG_FILE") 2>&1

# Function to print colored messages
print_message() {
  local color=$1
  local message=$2
  echo -e "${color}${ARROW}${message}${COLOR_RESET}"
}

# Install yay if not already installed
if ! command -v yay &>/dev/null; then
  print_message "$COLOR_YELLOW" "yay not found, installing yay..."
  sudo pacman -S --needed git base-devel | tee -a "$LOG_FILE" || { print_message "$COLOR_RED" "Failed to install required packages for yay."; exit 1; }
  git clone https://aur.archlinux.org/yay.git | tee -a "$LOG_FILE" || { print_message "$COLOR_RED" "Failed to clone yay repository."; exit 1; }
  cd yay
  makepkg -si | tee -a "$LOG_FILE" || { print_message "$COLOR_RED" "Failed to build and install yay."; exit 1; }
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
    yay -S --noconfirm "$package" | tee -a "$LOG_FILE" || { print_message "$COLOR_RED" "Failed to install $package with yay."; exit 1; }
  fi
}

# List of system packages to install
system_packages=(
  # Shells
  "zsh" # Z shell, an extended version of bash

  # System utilities
  "btop"               # Resource monitor for CPU, RAM, and more
  "neovim"             # Neovim, modern Vim text editor
  "lazygit"            # Simple terminal UI for Git
  "tmux"               # Terminal multiplexer to manage multiple sessions
  "neofetch"           # System information tool displaying configs in terminal
  "stow"               # Symlink manager to manage dotfiles
  "blueman"            # Bluetooth manager
  "systemd-homed"      # Manages user home directories as portable images or LUKS volumes
  "gnome-disk-utility" # Disk utility for GNOME
  "nautilus"           # File manager for GNOME
  "timeshift"          # System restore utility

  # Graphics and display
  "hyprpaper"
  "hyprland"          # A dynamic tiling Wayland compositor
  "wayland"           # Display server protocol, replacement for X11
  "wayland-protocols" # Extensions to the Wayland protocol
  "wlroots"           # Modular Wayland compositor library
  "xorg-xwayland"     # X server running as a Wayland client for compatibility
  "qt5-wayland"       # Wayland integration plugin for Qt5 apps
  "qt6-wayland"       # Wayland integration plugin for Qt6 apps
  "wofi"              # Application launcher and menu for Wayland
  "waybar"            # Highly customizable status bar for Wayland
  "wlogout"           # Logout menu for Wayland
  "swappy"            # GUI for annotating screenshots in Wayland
  "xdg-desktop-portal-gtk" # allow gnome theme to be set 

  # Fonts
  "ttf-dejavu"                # DejaVu TrueType fonts
  "ttf-freefont"              # FreeFont TrueType fonts
  "fontconfig"                # Font configuration and customization library
  "noto-fonts"                # Google Noto fonts
  "ttf-hack"                  # Hack programming font
  "ttf-material-design-icons" # Material Design icons font
  "ttf-font-awesome"

  # Networking
  "networkmanager"         # Tool for managing network connections
  "network-manager-applet" # Applet for NetworkManager in system tray
  "xorg-server-xwayland"   # Xorg server for X11 applications in Wayland

  # Audio and video
  "pavucontrol"    # PulseAudio volume control GUI
  "pulseaudio"     # Sound server for Linux
  "playerctl"      # CLI music player controller
  "pipewire"       # PipeWire, a low-latency audio/video router and application framework
  "pipewire-alsa"  # ALSA configuration for PipeWire
  "pipewire-pulse" # PulseAudio replacement for PipeWire
  "pipewire-jack"  # JACK support for PipeWire

  # NVIDIA drivers
  'nvidia'          # NVIDIA driver
  'nvidia-utils'    # NVIDIA driver utilities
  'nvidia-settings' # NVIDIA settings utility

  # Other
  "polkit-gnome"                    # Authentication agent for policy kit in GNOME
  "wl-clipboard"                    # Clipboard manager for Wayland
  "kitty"                           # GPU-based terminal emulator
  "yazi"                            # Console-based file manager with VI key bindings
  "python-pillow"                   # Python Imaging Library (Pillow)
  "xdg-desktop-portal-hyprland-git" # Hyprland-specific implementation of xdg-desktop-portal
  "insomnia"                        # REST client for debugging APIs
  "fzf"                             # Command-line fuzzy finder
)

# List of workspace packages to install
workspace_packages=(
  # JavaScript and Node.js
  "nodejs" # Node.js, JavaScript runtime for server-side programming
  "npm"    # Node Package Manager, used to manage JavaScript packages
  "nvm"    # Node Version Manager, tool for managing multiple Node.js versions

  # Python
  "python"     # Python programming language
  "python-pip" # Python package installer

  # Containers and virtualization
  "docker"         # Docker, containerization platform
  "docker-compose" # Docker Compose, tool for defining and running multi-container Docker applications

  # PHP and databases
  "php"      # PHP, server-side scripting language
  "sqlite"   # SQLite, lightweight SQL database engine
  "laravel"  # Laravel, PHP web framework (can be installed via Composer)
  "composer" # Composer, dependency manager for PHP
  "datagrip" # Database management tool

  # Java and Android development
  'jre-openjdk'    # OpenJDK Java Runtime Environment
  "android-studio" # Android Studio, IDE for Android development
)

# Install system packages
if [ "$1" == "system" ]; then
  print_message "$COLOR_YELLOW" "Installing system packages..."
  for package in "${system_packages[@]}"; do
    install_package "$package"
  done
elif [ "$1" == "workspace" ]; then
  print_message "$COLOR_YELLOW" "Installing workspace packages..."
  for package in "${workspace_packages[@]}"; do
    install_package "$package"
  done
else
  print_message "$COLOR_YELLOW" "Installing system packages..."
  for package in "${system_packages[@]}"; do
    install_package "$package"
  done

  print_message "$COLOR_YELLOW" "Installing workspace packages..."
  for package in "${workspace_packages[@]}"; do
    install_package "$package"
  done
  # Clone and stow dotfiles if not already present
  if [ ! -d "dotfiles" ]; then
    print_message "$COLOR_YELLOW" "Cloning dotfiles repository..."
    git clone https://github.com/felixoakz/dotfiles.git | tee -a "$LOG_FILE" || { print_message "$COLOR_RED" "Failed to clone dotfiles repository."; exit 1; }
  fi

  print_message "$COLOR_YELLOW" "Stowing dotfiles..."
  cd dotfiles
  stow . | tee -a "$LOG_FILE" || { print_message "$COLOR_RED" "Failed to stow dotfiles."; exit 1; }
  cd ..

  # Change default shell to zsh
  print_message "$COLOR_YELLOW" "Changing default shell to zsh..."
  chsh -s "$(which zsh)" | tee -a "$LOG_FILE" || { print_message "$COLOR_RED" "Failed to change default shell to zsh."; exit 1; }
fi
