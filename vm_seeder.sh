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

# Update and upgrade system
print_message "$COLOR_YELLOW" "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# List of packages to install
packages=(
  "git"          # Version control system
  "curl"         # Command-line tool for transferring data
  "python3"      # Python programming language
  "python3-pip"  # Python package manager
  "neovim"       # Modern Vim text editor
  "tmux"         # Terminal multiplexer
  "kitty"        # Terminal emulator
  "nginx"        # Web server
  "zsh"          # Z shell
  "certbot"      # Certbot for SSL certificate management
  "python3-certbot-nginx"  # Certbot plugin for Nginx
)

# Install each package
for package in "${packages[@]}"; do
  print_message "$COLOR_YELLOW" "Installing $package..."
  sudo apt install -y $package || {
    print_message "$COLOR_RED" "Failed to install $package."
    exit 1
  }
done

# Set Zsh as default shell
if [ "$(echo $SHELL)" != "$(which zsh)" ]; then
  print_message "$COLOR_YELLOW" "Changing default shell to Zsh..."
  chsh -s "$(which zsh)" || {
    print_message "$COLOR_RED" "Failed to change default shell to Zsh."
    exit 1
  }
fi

# Install Oh My Zsh
print_message "$COLOR_YELLOW" "Installing Oh My Zsh..."
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || {
  print_message "$COLOR_RED" "Failed to install Oh My Zsh."
  exit 1
}

# Configure SSL Certificate
DOMAIN="f-server.ddns.net"

print_message "$COLOR_YELLOW" "Obtaining SSL certificate for $DOMAIN..."
sudo certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos --email your_email@example.com || {
  print_message "$COLOR_RED" "Failed to obtain SSL certificate."
  exit 1
}

# Test Nginx configuration
print_message "$COLOR_YELLOW" "Testing Nginx configuration..."
sudo nginx -t || {
  print_message "$COLOR_RED" "Nginx configuration test failed."
  exit 1
}

# Reload Nginx to apply changes
print_message "$COLOR_YELLOW" "Reloading Nginx..."
sudo systemctl reload nginx || {
  print_message "$COLOR_RED" "Failed to reload Nginx."
  exit 1
}

print_message "$COLOR_GREEN" "Installation completed successfully!"
