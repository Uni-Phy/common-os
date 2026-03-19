#!/bin/bash
# Common Compute OS - Ollama Lite Uninstaller
# Removes Ollama and the web UI cleanly
# Usage: sudo ./scripts/uninstall.sh

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RESET='\033[0m'

info()    { echo -e "${GREEN}[+]${RESET} $1"; }
warn()    { echo -e "${YELLOW}[!]${RESET} $1"; }

if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}[✗]${RESET} This script must be run as root (use sudo)"
    exit 1
fi

echo ""
echo "This will remove:"
echo "  - coco-web-ui service and /opt/coco-web-ui"
echo "  - Ollama service override (Ollama itself stays installed)"
echo ""
read -p "Continue? [y/N] " confirm
if [[ "$confirm" != [yY] ]]; then
    echo "Aborted."
    exit 0
fi

# Stop and remove web UI
info "Stopping web UI service..."
systemctl stop coco-web-ui 2>/dev/null || true
systemctl disable coco-web-ui 2>/dev/null || true
rm -f /etc/systemd/system/coco-web-ui.service

info "Removing web UI files..."
rm -rf /opt/coco-web-ui

# Remove Ollama override (keep Ollama itself)
info "Removing Ollama network override..."
rm -f /etc/systemd/system/ollama.service.d/override.conf
rmdir /etc/systemd/system/ollama.service.d 2>/dev/null || true

systemctl daemon-reload

# Optionally remove Ollama entirely
echo ""
read -p "Also remove Ollama entirely? [y/N] " remove_ollama
if [[ "$remove_ollama" == [yY] ]]; then
    info "Stopping Ollama..."
    systemctl stop ollama 2>/dev/null || true
    systemctl disable ollama 2>/dev/null || true
    rm -f /etc/systemd/system/ollama.service
    rm -f /usr/local/bin/ollama
    rm -rf /usr/share/ollama
    info "Ollama removed."

    read -p "Also delete downloaded models (~/.ollama)? [y/N] " remove_models
    if [[ "$remove_models" == [yY] ]]; then
        rm -rf /root/.ollama
        rm -rf /home/*/.ollama
        info "Models removed."
    fi
fi

systemctl daemon-reload
info "Uninstall complete."
