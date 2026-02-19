#!/bin/bash
# =============================================
# DovezU - Unified Auto-Installation Script
# =============================================
# This script automatically installs the entire
# DovezU Food Delivery Management System
# =============================================
# Usage: sudo bash auto-install.sh
# =============================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
PROJECT_DIR="/opt/foodtech"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Banner
echo ""
echo -e "${PURPLE}╔═══════════════════════════════════════════════════╗${NC}"
echo -e "${PURPLE}║                                                   ║${NC}"
echo -e "${PURPLE}║         🚀 DovezU Auto-Installer v1.0            ║${NC}"
echo -e "${PURPLE}║     Food Delivery Management System Setup        ║${NC}"
echo -e "${PURPLE}║                                                   ║${NC}"
echo -e "${PURPLE}╚═══════════════════════════════════════════════════╝${NC}"
echo ""

# Check root privileges
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}❌ This script must be run as root${NC}"
    echo -e "${YELLOW}   Please run: sudo bash auto-install.sh${NC}"
    exit 1
fi

# Detect installation type
echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
echo -e "${BLUE}🔍 Detecting system configuration...${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
echo ""

# Check if Docker is available or can be installed
DOCKER_AVAILABLE=false

# Check virtualization support
if [ -e /proc/user_beancounters ] || [ -d /proc/vz ]; then
    echo -e "${YELLOW}⚠️  OpenVZ/Virtuozzo container detected${NC}"
    echo -e "${YELLOW}   Docker may not be available${NC}"
    VIRT_TYPE="openvz"
elif systemd-detect-virt &>/dev/null; then
    VIRT_TYPE=$(systemd-detect-virt)
    echo -e "${GREEN}✓ Virtualization: ${VIRT_TYPE}${NC}"

    if [ "$VIRT_TYPE" != "openvz" ] && [ "$VIRT_TYPE" != "lxc" ]; then
        DOCKER_AVAILABLE=true
    fi
else
    echo -e "${GREEN}✓ Running on bare metal or compatible VM${NC}"
    DOCKER_AVAILABLE=true
fi

# Check if Docker is already installed
if command -v docker &> /dev/null; then
    echo -e "${GREEN}✓ Docker is already installed: $(docker --version)${NC}"
    DOCKER_AVAILABLE=true
fi

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
echo -e "${BLUE}📋 Installation Options${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
echo ""

if [ "$DOCKER_AVAILABLE" = true ]; then
    echo -e "${GREEN}1) Docker Installation (Recommended)${NC}"
    echo -e "   ${CYAN}├─${NC} Isolated environments"
    echo -e "   ${CYAN}├─${NC} Easy updates and rollbacks"
    echo -e "   ${CYAN}├─${NC} Better resource management"
    echo -e "   ${CYAN}└─${NC} Simpler deployment"
    echo ""
fi

echo -e "${GREEN}2) Native Installation${NC}"
echo -e "   ${CYAN}├─${NC} Direct installation on host"
echo -e "   ${CYAN}├─${NC} Better performance"
echo -e "   ${CYAN}├─${NC} Works on OpenVZ/LXC"
echo -e "   ${CYAN}└─${NC} More control over services"
echo ""

echo -e "${GREEN}3) Fresh Installation${NC}"
echo -e "   ${CYAN}├─${NC} Clean slate installation"
echo -e "   ${CYAN}├─${NC} Removes existing components"
echo -e "   ${CYAN}├─${NC} Recommended for troubleshooting"
echo -e "   ${CYAN}└─${NC} Full system reconfiguration"
echo ""

if [ "$DOCKER_AVAILABLE" = true ]; then
    DEFAULT_CHOICE=1
else
    DEFAULT_CHOICE=2
    echo -e "${YELLOW}⚠️  Docker not available, defaulting to Native Installation${NC}"
    echo ""
fi

# Prompt for installation type
read -p "$(echo -e ${CYAN}Enter your choice [${DEFAULT_CHOICE}]: ${NC})" INSTALL_CHOICE
INSTALL_CHOICE=${INSTALL_CHOICE:-$DEFAULT_CHOICE}

echo ""

# Validate choice
case $INSTALL_CHOICE in
    1)
        if [ "$DOCKER_AVAILABLE" != true ]; then
            echo -e "${RED}❌ Docker installation not available on this system${NC}"
            echo -e "${YELLOW}   Falling back to Native Installation${NC}"
            INSTALL_CHOICE=2
        else
            INSTALL_TYPE="docker"
            INSTALL_NAME="Docker Installation"
        fi
        ;;
    2)
        INSTALL_TYPE="native"
        INSTALL_NAME="Native Installation"
        ;;
    3)
        INSTALL_TYPE="fresh"
        INSTALL_NAME="Fresh Installation"
        ;;
    *)
        echo -e "${RED}❌ Invalid choice${NC}"
        exit 1
        ;;
esac

echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Selected: ${INSTALL_NAME}${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
echo ""

# Confirm installation
echo -e "${YELLOW}⚠️  This will install/modify:${NC}"
echo -e "   • System packages"
echo -e "   • Database (PostgreSQL)"
echo -e "   • Web server (Nginx)"
echo -e "   • Application files in ${PROJECT_DIR}"
echo ""
read -p "$(echo -e ${CYAN}Continue with installation? [y/N]: ${NC})" CONFIRM
CONFIRM=${CONFIRM:-n}

if [[ ! $CONFIRM =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Installation cancelled${NC}"
    exit 0
fi

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}🚀 Starting ${INSTALL_NAME}...${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
echo ""

# Prepare project directory
echo -e "${BLUE}[1/3]${NC} Preparing project directory..."
mkdir -p "$PROJECT_DIR"

# Copy project files if running from different location
if [ "$SCRIPT_DIR" != "$PROJECT_DIR" ]; then
    echo -e "${BLUE}      Copying project files...${NC}"
    rsync -a --exclude='.git' --exclude='node_modules' --exclude='vendor' "$SCRIPT_DIR/" "$PROJECT_DIR/"
fi

cd "$PROJECT_DIR"
echo -e "${GREEN}  ✅ Project directory ready: ${PROJECT_DIR}${NC}"
echo ""

# Setup environment file
echo -e "${BLUE}[2/3]${NC} Configuring environment..."
if [ ! -f "$PROJECT_DIR/.env" ]; then
    if [ -f "$PROJECT_DIR/.env.production" ]; then
        cp "$PROJECT_DIR/.env.production" "$PROJECT_DIR/.env"
        echo -e "${GREEN}  ✅ Created .env from template${NC}"
        echo -e "${YELLOW}  ⚠️  IMPORTANT: Review and update .env file with your credentials!${NC}"
    else
        echo -e "${RED}  ❌ No .env.production template found${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}  ✅ Using existing .env file${NC}"
fi
echo ""

# Execute appropriate installation script
echo -e "${BLUE}[3/3]${NC} Running installation script..."
echo ""

case $INSTALL_TYPE in
    docker)
        if [ -f "$PROJECT_DIR/install.sh" ]; then
            bash "$PROJECT_DIR/install.sh"
        else
            echo -e "${RED}❌ install.sh not found${NC}"
            exit 1
        fi
        ;;
    native)
        if [ -f "$PROJECT_DIR/install-native.sh" ]; then
            bash "$PROJECT_DIR/install-native.sh"
        else
            echo -e "${RED}❌ install-native.sh not found${NC}"
            exit 1
        fi
        ;;
    fresh)
        if [ -f "$PROJECT_DIR/install-fresh.sh" ]; then
            bash "$PROJECT_DIR/install-fresh.sh"
        else
            echo -e "${RED}❌ install-fresh.sh not found${NC}"
            exit 1
        fi
        ;;
esac

# Final message
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')

echo ""
echo -e "${PURPLE}╔═══════════════════════════════════════════════════╗${NC}"
echo -e "${PURPLE}║                                                   ║${NC}"
echo -e "${PURPLE}║          🎉 Installation Complete!               ║${NC}"
echo -e "${PURPLE}║                                                   ║${NC}"
echo -e "${PURPLE}╚═══════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}  🌐 Admin Panel:  ${NC}http://${SERVER_IP}/admin"
echo -e "${GREEN}  🔧 API Endpoint: ${NC}http://${SERVER_IP}/api/v1"
echo -e "${GREEN}  📊 API Docs:     ${NC}http://${SERVER_IP}/api/v1/docs"
echo ""
echo -e "${CYAN}  📧 Default Login:    ${NC}admin@foodtech.ru"
echo -e "${CYAN}  🔑 Default Password: ${NC}password"
echo ""
echo -e "${YELLOW}  ⚠️  SECURITY CHECKLIST:${NC}"
echo -e "     1. Review ${PROJECT_DIR}/.env"
echo -e "     2. Change default passwords"
echo -e "     3. Configure SSL certificate"
echo -e "     4. Update firewall rules"
echo -e "     5. Set up automated backups"
echo ""
echo -e "${BLUE}  📖 Documentation:${NC}"
echo -e "     • Full Guide: ${PROJECT_DIR}/SETUP_GUIDE.md"
echo -e "     • Architecture: ${PROJECT_DIR}/ARCHITECTURE.md"
echo -e "     • AI Instructions: ${PROJECT_DIR}/AI_INSTRUCTIONS.md"
echo -e "     • Troubleshooting: ${PROJECT_DIR}/FIXES_README.md"
echo ""
echo -e "${CYAN}  🛠️  Useful Commands:${NC}"

if [ "$INSTALL_TYPE" = "docker" ]; then
    echo -e "     docker compose logs -f          # View logs"
    echo -e "     docker compose restart          # Restart all services"
    echo -e "     docker compose exec admin bash  # Access admin container"
else
    echo -e "     systemctl status nginx postgresql redis-server php8.2-fpm"
    echo -e "     cd ${PROJECT_DIR}/admin && php artisan tinker"
    echo -e "     tail -f ${PROJECT_DIR}/admin/storage/logs/laravel.log"
fi

echo ""
echo -e "${GREEN}  🎊 Thank you for using DovezU!${NC}"
echo ""

# Store installation info
cat > "$PROJECT_DIR/.install-info" << EOF
Installation Date: $(date)
Installation Type: ${INSTALL_TYPE}
Server IP: ${SERVER_IP}
PHP Version: $(php -v 2>/dev/null | head -n1 || echo "N/A")
Python Version: $(python3 --version 2>/dev/null || echo "N/A")
PostgreSQL Version: $(psql --version 2>/dev/null || echo "N/A")
EOF

echo -e "${BLUE}Installation info saved to: ${PROJECT_DIR}/.install-info${NC}"
echo ""

exit 0
