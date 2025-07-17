#!/bin/bash

# ==============================================================================
# Ubuntu Bootstrap Master Script
#
# Description:
# This script combines multiple setup, hardening, and utility scripts into a
# single, menu-driven tool for bootstrapping a new Ubuntu server. It now runs
# a system discovery automatically on startup.
#
# Includes functionality for:
#   - Creating a secure sudo user with SSH key authentication.
#   - Hardening the SSH server configuration.
#   - Installing and configuring Oh My Posh.
#   - Uninstalling Oh My Posh.
#   - Installing Docker and Docker Compose.
#   - Running a system discovery report.
#
# Author: RLMX Tech/Gemini
# Version: 1.5
# ==============================================================================

# --- Helper Functions & Colors ---
set -o pipefail

# Color codes for output
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to check for sudo/root privileges
check_sudo() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}This operation requires root privileges. Please run with sudo.${NC}"
        exit 1
    fi
}

# --- MODULE 1: Secure User Setup and SSH Hardening ---
secure_user_and_harden_ssh() {
    check_sudo

    echo -e "${CYAN}--- Starting Secure User Setup and SSH Hardening ---${NC}"

    # --- User Input ---
    read -r -p "Enter the username for the new sudo user: " NEW_USER
    if [ -z "$NEW_USER" ]; then
        echo -e "${RED}Error: No username entered. Exiting.${NC}" >&2
        exit 1
    fi
    if id "$NEW_USER" &>/dev/null; then
        echo -e "${RED}Error: User '$NEW_USER' already exists. Exiting.${NC}" >&2
        exit 1
    fi

    read -r -p "Enter the GitHub username to fetch the SSH public key from: " GITHUB_USER
    if [ -z "$GITHUB_USER" ]; then
        echo -e "${RED}Error: No GitHub username entered. Exiting.${NC}" >&2
        exit 1
    fi

    # 1. Create the new user and add to necessary groups
    echo "[1/6] Creating user '$NEW_USER' and adding to groups..."
    adduser --quiet "$NEW_USER"
    usermod -aG sudo "$NEW_USER"
    # Create docker group if it doesn't exist, then add the new user to it.
    groupadd --force docker
    usermod -aG docker "$NEW_USER"
    echo -e "${GREEN}✅ User created and added to 'sudo' and 'docker' groups.${NC}\n"

    # 2. Set up user directories
    echo "[2/6] Setting up user directories (.ssh and docker)..."
    USER_HOME="/home/$NEW_USER"
    mkdir -p "$USER_HOME/.ssh"
    mkdir -p "$USER_HOME/docker"
    touch "$USER_HOME/.ssh/authorized_keys"
    echo -e "${GREEN}✅ User directories created.${NC}\n"

    # 3. Fetch and add GitHub SSH key
    echo "[3/6] Fetching SSH key from github.com/$GITHUB_USER.keys..."
    if curl -s "https://github.com/$GITHUB_USER.keys" >> "$USER_HOME/.ssh/authorized_keys"; then
        echo -e "${GREEN}✅ SSH key fetched and added successfully.${NC}\n"
    else
        echo -e "${RED}Error: Failed to fetch SSH key for GitHub user '$GITHUB_USER'. Please check the username.${NC}" >&2
        exit 1
    fi

    # 4. Set correct ownership and permissions
    echo "[4/6] Setting ownership and permissions..."
    chown -R "$NEW_USER:$NEW_USER" "$USER_HOME/.ssh"
    chown -R "$NEW_USER:$NEW_USER" "$USER_HOME/docker"
    chmod 700 "$USER_HOME/.ssh"
    chmod 600 "$USER_HOME/.ssh/authorized_keys"
    echo -e "${GREEN}✅ Permissions set correctly.${NC}\n"

    # 5. Configure passwordless sudo
    echo "[5/6] Configuring passwordless sudo..."
    SUDOERS_FILE="/etc/sudoers.d/01-$NEW_USER-nopasswd"
    echo "$NEW_USER ALL=(ALL) NOPASSWD:ALL" > "$SUDOERS_FILE"
    chmod 440 "$SUDOERS_FILE"
    echo -e "${GREEN}✅ Passwordless sudo configured.${NC}\n"

    # 6. Harden SSH Configuration
    echo "[6/6] Hardening SSH server configuration..."
    SSHD_CONFIG_PATH="/etc/ssh/sshd_config"
    BACKUP_PATH="${SSHD_CONFIG_PATH}.bak.$(date +%F-%T)"
    cp "$SSHD_CONFIG_PATH" "$BACKUP_PATH"
    echo "Backup of sshd_config created at $BACKUP_PATH"

    sed -i -e 's/^#?PermitRootLogin.*/PermitRootLogin no/' \
             -e 's/^#?PasswordAuthentication.*/PasswordAuthentication no/' \
             -e 's/^#?ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/' \
             -e 's/^#?UsePAM.*/UsePAM yes/' \
             "$SSHD_CONFIG_PATH"
    
    # Add AllowUsers directive
    echo "AllowUsers $NEW_USER" >> "$SSHD_CONFIG_PATH"

    echo -e "${GREEN}✅ SSH server hardened.${NC}\n"
    
    echo -e "${YELLOW}--- 🚀 Initial Setup Complete! ---${NC}"
    echo "IMPORTANT: Please restart the SSH service to apply changes: sudo systemctl restart sshd"
    echo "Then, test login in a NEW terminal: ssh $NEW_USER@<your_server_ip>"
}

# --- MODULE 2: Oh My Posh Installation ---
install_oh_my_posh() {
    check_sudo
    SUDO_USER=$(logname) # Get the user who invoked sudo
    USER_HOME="/home/$SUDO_USER"
    
    echo -e "${CYAN}--- Starting Oh My Posh Installation ---${NC}"

    # Dependency Check
    echo "Checking dependencies..."
    apt-get update > /dev/null
    apt-get install -y curl wget unzip fontconfig > /dev/null
    echo -e "${GREEN}Dependencies are satisfied.${NC}"

    # Install Oh My Posh
    echo "Installing Oh My Posh..."
    curl -s https://ohmyposh.dev/install.sh | bash -s -- -d /usr/local/bin
    
    # Copy Themes
    echo "Copying themes..."
    ROOT_THEME_DIR="/root/.cache/oh-my-posh/themes"
    USER_THEME_DIR="$USER_HOME/.cache/oh-my-posh"
    if [ -d "$ROOT_THEME_DIR" ]; then
        mkdir -p "$USER_THEME_DIR/themes"
        cp "$ROOT_THEME_DIR"/*.omp.json "$USER_THEME_DIR/themes/"
        chown -R "$SUDO_USER:$SUDO_USER" "$USER_HOME/.cache"
    fi

    # Install Font
    echo "Installing Caskaydia Cove Nerd Font..."
    FONT_DIR="/usr/local/share/fonts/cascadia"
    if [ ! -d "$FONT_DIR" ]; then
        mkdir -p "$FONT_DIR"
        wget -q https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/CascadiaCode.zip -O /tmp/CascadiaCode.zip
        unzip -q /tmp/CascadiaCode.zip -d "$FONT_DIR"
        rm /tmp/CascadiaCode.zip
        fc-cache -f -v > /dev/null
    fi

    # Configure .bashrc
    echo "Configuring .bashrc..."
    BASHRC_FILE="$USER_HOME/.bashrc"
    THEME_NAME="catppuccin"
    USER_THEME_PATH="$USER_THEME_DIR/themes/$THEME_NAME.omp.json"
    INIT_COMMAND="eval \"\$(oh-my-posh init bash --config '$USER_THEME_PATH')\""
    
    if grep -q "oh-my-posh init" "$BASHRC_FILE"; then
        sed -i "/oh-my-posh init/c\\$INIT_COMMAND" "$BASHRC_FILE"
    else
        echo -e "\n# Initialize Oh My Posh\n$INIT_COMMAND" >> "$BASHRC_FILE"
    fi

    echo -e "${GREEN}✅ Oh My Posh installation complete!${NC}"
    echo "Please restart your terminal or run 'source ~/.bashrc'."
    echo "Don't forget to set 'CaskaydiaCove Nerd Font' in your terminal's settings."
}

# --- MODULE 3: Oh My Posh Uninstallation ---
uninstall_oh_my_posh() {
    check_sudo
    SUDO_USER=$(logname)
    USER_HOME="/home/$SUDO_USER"
    BASHRC_FILE="$USER_HOME/.bashrc"

    echo -e "${CYAN}--- Starting Oh My Posh Uninstallation ---${NC}"

    # Remove from .bashrc
    if [ -f "$BASHRC_FILE" ]; then
        sed -i "/oh-my-posh init/d" "$BASHRC_FILE"
        sed -i "/# Initialize Oh My Posh/d" "$BASHRC_FILE"
    fi

    # Remove executable
    rm -f /usr/local/bin/oh-my-posh

    # Remove themes
    rm -rf "$USER_HOME/.cache/oh-my-posh"

    # Ask to remove font
    FONT_DIR="/usr/local/share/fonts/cascadia"
    if [ -d "$FONT_DIR" ]; then
        read -r -p "Do you want to uninstall the Caskaydia Cove Nerd Font? (y/N) " -n 1
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$FONT_DIR"
            fc-cache -f -v > /dev/null
            echo -e "${GREEN}Font uninstalled.${NC}"
        fi
    fi
    
    echo -e "${GREEN}✅ Oh My Posh uninstallation complete!${NC}"
    echo "Please restart your terminal or run 'source ~/.bashrc'."
}

# --- MODULE 4: Docker Installation ---
install_docker() {
    check_sudo
    SUDO_USER=$(logname)

    echo -e "${CYAN}--- Starting Docker Installation ---${NC}"

    # 1. Set up Docker's apt repository.
    echo "[1/3] Setting up Docker's APT repository..."
    apt-get update
    apt-get install -y ca-certificates curl gnupg
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg

    # shellcheck disable=SC1091
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update
    echo -e "${GREEN}✅ Repository setup complete.${NC}\n"

    # 2. Install Docker packages
    echo "[2/3] Installing Docker Engine and plugins..."
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    echo -e "${GREEN}✅ Docker packages installed.${NC}\n"

    # 3. Add user to the docker group
    echo "[3/3] Adding user '$SUDO_USER' to the 'docker' group..."
    usermod -aG docker "$SUDO_USER"
    echo -e "${GREEN}✅ User added to docker group.${NC}\n"

    echo -e "${YELLOW}--- 🚀 Docker Installation Complete! ---${NC}"
    echo "IMPORTANT: You must log out and log back in for the group changes to take effect."
    echo "After logging back in, you can run 'docker run hello-world' to test the installation."
}


# --- MODULE 5: System Discovery ---
system_discovery() {
    echo -e "${CYAN}--- Running System Discovery ---${NC}"
    OUTPUT="/tmp/system_discovery_linux_$(date +%Y%m%d_%H%M%S).log"
    {
        echo "===== SYSTEM DISCOVERY REPORT (LINUX) ====="
        echo "Timestamp: $(date)"
        echo -e "\n=== OS Information ==="
        uname -a
        cat /etc/os-release
        echo -e "\n=== Kernel Version ==="
        uname -r
        echo -e "\n=== Block Devices ==="
        lsblk -f
        echo -e "\n=== Mounted File Systems ==="
        df -hT
        echo -e "\n=== User ==="
        echo "User: $(whoami)"
        echo "Home: $HOME"
    } | tee "$OUTPUT"
    echo -e "\n${GREEN}✅ System discovery report saved to $OUTPUT${NC}"
}


# --- Main Menu ---
main_menu() {
    while true; do
        echo -e "\n${YELLOW}--- Ubuntu Bootstrap Script Menu ---${NC}"
        echo "Please choose an option:"
        echo "1. Initial Server Setup (Create Sudo User & Harden SSH)"
        echo "2. Install Oh My Posh"
        echo "3. Uninstall Oh My Posh"
        echo "4. Install Docker"
        echo "5. Run System Discovery"
        echo "6. Exit"
        echo ""
        read -r -p "Enter your choice [1-6]: " choice

        case $choice in
            1)
                secure_user_and_harden_ssh
                ;;
            2)
                install_oh_my_posh
                ;;
            3)
                uninstall_oh_my_posh
                ;;
            4)
                install_docker
                ;;
            5)
                system_discovery
                ;;
            6)
                echo "Exiting."
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option. Please try again.${NC}"
                ;;
        esac
    done
}

# --- Script Entry Point ---
# Run system discovery automatically on script start
system_discovery

echo -e "\n${YELLOW}----------------------------------------------------${NC}"
echo -e "${CYAN}System discovery complete. Proceeding to main menu...${NC}"

main_menu

# --- End of Script ---
# This script is designed to be run on a fresh Ubuntu server installation.
# It combines multiple setup, hardening, and utility scripts into a single, menu-driven tool.
# Ensure you have the necessary permissions and dependencies installed before running this script.
# For any issues or contributions, please refer to the repository on GitHub.