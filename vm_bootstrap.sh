#!/bin/bash

# Log file for installation
LOG_FILE="vm_bootstrap.log"

# Colors for messaging
COLOR_RESET="\033[0m"
COLOR_GREEN="\033[32m"
COLOR_RED="\033[31m"
COLOR_YELLOW="\033[33m"
COLOR_BLUE="\033[34m"  # Color for log file output
ARROW="---> "

# Redirect script output to both terminal and log file, coloring only the log output
exec > >(tee >(sed "s/^/${COLOR_BLUE}/;s/$/${COLOR_RESET}/" >> "$LOG_FILE")) 2>&1

# Function to print messages in color for terminal
print_message() {
  echo -e "${1}${ARROW}${2}${COLOR_RESET}"
}

# Remove unnecessary packages to keep environment minimal
unnecessary_packages=(
  "nano"          # Text editor
  "vim-tiny"      # Minimal Vim version, unnecessary if using Neovim
  "snapd"         # Snap daemon, remove if not using Snap packages
)

print_message "$COLOR_YELLOW" "Removing unnecessary packages..."
for package in "${unnecessary_packages[@]}"; do
  if dpkg -l | grep -q "^ii  $package"; then
    print_message "$COLOR_YELLOW" "Removing $package..."
    sudo apt remove --purge -y $package || {
      print_message "$COLOR_RED" "Failed to remove $package."
      continue
    }
  else
    print_message "$COLOR_GREEN" "$package not installed, skipping."
  fi
done

# Update and upgrade system
print_message "$COLOR_YELLOW" "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Define essential packages
packages=(
  "git"            # Version control system
  "curl"           # Command line tool for transferring data
  "python3"        # Python programming language
  "python3-pip"    # Python package manager
  "neovim"         # Vim-based text editor
  "tmux"           # Terminal multiplexer
  "zsh"            # Z shell, for better terminal experience
)

# Install each package
for package in "${packages[@]}"; do
  print_message "$COLOR_YELLOW" "Installing $package..."
  sudo apt install -y $package || {
    print_message "$COLOR_RED" "Failed to install $package."
    exit 1
  }
done

# Set Zsh as default shell if not already
if [ "$SHELL" != "$(which zsh)" ]; then
  print_message "$COLOR_YELLOW" "Changing default shell to Zsh..."
  sudo chsh -s "$(which zsh)" "$USER" || {
    print_message "$COLOR_RED" "Failed to change default shell to Zsh."
    exit 1
  }
fi

# Prompt for domain and email for SSL setup
read -p "Enter your domain for SSL setup (leave blank to skip): " DOMAIN
read -p "Enter your email for SSL registration (leave blank to skip): " EMAIL

# SSL setup with Certbot if domain and email are provided
if [[ -n "$DOMAIN" && -n "$EMAIL" ]]; then
  print_message "$COLOR_YELLOW" "Installing Certbot and Nginx..."
  sudo apt install -y nginx certbot python3-certbot-nginx || {
    print_message "$COLOR_RED" "Failed to install Certbot or Nginx."
    exit 1
  }

  print_message "$COLOR_YELLOW" "Obtaining SSL certificate for $DOMAIN..."
  sudo certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos --email "$EMAIL" || {
    print_message "$COLOR_RED" "Failed to obtain SSL certificate."
    exit 1
  }

  # Test Nginx configuration and reload if successful
  print_message "$COLOR_YELLOW" "Testing Nginx configuration..."
  sudo nginx -t && sudo systemctl reload nginx || {
    print_message "$COLOR_RED" "Failed to reload Nginx."
    exit 1
  }
else
  print_message "$COLOR_YELLOW" "SSL setup skipped."
fi

# Move Nginx config to /etc/nginx/
print_message "$COLOR_YELLOW" "Moving Nginx configuration to /etc/nginx/default..."
if [ -f "default" ]; then
  sudo mv default /etc/nginx/sites-available/default || {
    print_message "$COLOR_RED" "Failed to move Nginx configuration."
    exit 1
  }

  # Set correct permissions
  sudo chown root:root /etc/nginx/sites-available/default || {
    print_message "$COLOR_RED" "Failed to set permissions for Nginx config."
    exit 1
  }
else
  print_message "$COLOR_RED" "Nginx configuration file not found."
  exit 1
fi

print_message "$COLOR_GREEN" "Installation completed successfully. Restart your shell or log out/in to start using Zsh as default."
