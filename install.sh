#!/bin/bash
# Common Compute OS - Ollama Lite Installer
# Installs Ollama + nextjs-ollama-llm-ui on Raspberry Pi OS
# Usage: sudo ./install.sh

set -e

# --- Configuration ---
WEB_UI_DIR="/opt/coco-web-ui"
WEB_UI_BUILD_DIR="/tmp/coco-web-ui"
WEB_UI_VENDOR_DIR="$SCRIPT_DIR/vendor/coco-ollama-ui"
DEFAULT_MODEL="gemma3:1b"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RESET='\033[0m'

info()    { echo -e "${GREEN}[+]${RESET} $1"; }
warn()    { echo -e "${YELLOW}[!]${RESET} $1"; }
fail()    { echo -e "${RED}[✗]${RESET} $1"; exit 1; }

# --- Pre-flight checks ---
if [ "$(id -u)" -ne 0 ]; then
    fail "This script must be run as root (use sudo ./install.sh)"
fi

INSTALL_USER="${SUDO_USER:-$(whoami)}"
if [ "$INSTALL_USER" = "root" ]; then
    warn "No SUDO_USER detected. Service will run as root."
    warn "Consider running with: sudo -E ./install.sh as a regular user."
fi

info "Installer running as root, services will run as: $INSTALL_USER"

# Check architecture
ARCH=$(uname -m)
if [[ "$ARCH" != "aarch64" && "$ARCH" != "armv7l" ]]; then
    warn "Detected architecture: $ARCH (expected aarch64 or armv7l for RPi)"
    warn "Continuing anyway — Ollama may not have a binary for this arch."
fi

# --- Step 1: System update & dependencies ---
info "Updating package lists..."
apt-get update -qq

info "Installing required packages..."
apt-get install -y -qq curl git ca-certificates tar gzip unzip patch nginx avahi-daemon avahi-utils

# --- Step 2: Install Node.js (if not present) ---
if ! command -v node &>/dev/null; then
    info "Installing Node.js 18.x..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    apt-get install -y -qq nodejs
else
    NODE_VER=$(node --version)
    info "Node.js already installed: $NODE_VER"
fi

# --- Step 3: Install Ollama ---
if ! command -v ollama &>/dev/null; then
    info "Installing Ollama..."
    curl -fsSL https://ollama.ai/install.sh | sh
else
    info "Ollama already installed: $(ollama --version 2>/dev/null || echo 'unknown version')"
fi

# --- Step 4: Install and configure Ollama systemd service ---
info "Installing Ollama systemd service..."
cp "$SCRIPT_DIR/config/ollama.service" /etc/systemd/system/ollama.service
cp "$SCRIPT_DIR/config/ollama-watchdog.service" /etc/systemd/system/ollama-watchdog.service
cp "$SCRIPT_DIR/config/ollama-watchdog.timer" /etc/systemd/system/ollama-watchdog.timer
systemctl daemon-reload
systemctl enable ollama
systemctl enable ollama-watchdog.timer
systemctl restart ollama
systemctl start ollama-watchdog.timer

# Wait for Ollama to be ready
info "Waiting for Ollama to start..."
for i in $(seq 1 30); do
    if curl -sf http://localhost:11434/api/tags &>/dev/null; then
        break
    fi
    sleep 2
done

if ! curl -sf http://localhost:11434/api/tags &>/dev/null; then
    fail "Ollama failed to start. Check: journalctl -u ollama"
fi
info "Ollama is running and watchdog enabled."

# --- Step 5: Pull default model ---
info "Pulling default model: $DEFAULT_MODEL (this may take a while)..."
ollama pull "$DEFAULT_MODEL"
info "Model $DEFAULT_MODEL ready."

# --- Step 6: Build the bundled branded web UI ---
info "Preparing web UI from vendored source..."
rm -rf "$WEB_UI_BUILD_DIR"
mkdir -p "$WEB_UI_BUILD_DIR"

if [ ! -d "$WEB_UI_VENDOR_DIR" ]; then
    fail "Bundled web UI not found at $WEB_UI_VENDOR_DIR. Make sure the repository includes vendor/coco-ollama-ui."
fi

cp -a "$WEB_UI_VENDOR_DIR"/. "$WEB_UI_BUILD_DIR"/
WEB_UI_SRC_DIR="$WEB_UI_BUILD_DIR"

info "Installing npm dependencies (this may take a few minutes on RPi)..."
cd "$WEB_UI_SRC_DIR"
npm install

info "Building Next.js application..."
npm run build

info "Deploying to $WEB_UI_DIR ..."
rm -rf "$WEB_UI_DIR"
mv "$WEB_UI_SRC_DIR" "$WEB_UI_DIR"

# Fix ownership
chown -R "$INSTALL_USER:$INSTALL_USER" "$WEB_UI_DIR"

# --- Step 7: Install systemd service for web UI ---
info "Installing web UI systemd service..."
sed "s/__INSTALL_USER__/$INSTALL_USER/g" "$SCRIPT_DIR/config/coco-web-ui.service" \
    > /etc/systemd/system/coco-web-ui.service

systemctl daemon-reload
systemctl enable coco-web-ui
systemctl start coco-web-ui

# --- Step 8: Configure mDNS hostname ---
info "Configuring mDNS hostname: coco-chat.local..."
sed -i 's/^host-name=.*/host-name=coco-chat/' /etc/avahi/avahi-daemon.conf
systemctl enable avahi-daemon
systemctl restart avahi-daemon

# --- Step 9: Set up nginx reverse proxy ---
info "Configuring nginx reverse proxy on port 80..."
cat > /etc/nginx/sites-available/coco-chat <<'NGINX_CONFIG'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name coco-chat.local;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
NGINX_CONFIG

rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/coco-chat /etc/nginx/sites-enabled/coco-chat
nginx -t > /dev/null 2>&1
systemctl enable nginx
systemctl restart nginx

# Wait for web UI
sleep 3
if systemctl is-active --quiet coco-web-ui; then
    info "Web UI service is running."
else
    warn "Web UI service may not have started yet. Check: journalctl -u coco-web-ui"
fi

# --- Done ---
IP_ADDRESS=$(hostname -I | awk '{print $1}')
echo ""
echo "============================================="
echo " Common Compute OS - Ollama Lite"
echo "============================================="
echo " Hostname:    coco-chat.local"
echo " Chat UI:     http://coco-chat.local"
echo " Ollama API:  http://coco-chat.local:11434"
echo ""
echo " Direct IP (if .local fails):"
echo " Chat UI:     http://${IP_ADDRESS}"
echo " Ollama API:  http://${IP_ADDRESS}:11434"
echo " Model:       $DEFAULT_MODEL"
echo ""
echo " Test it:"
echo "   curl http://coco-chat.local:11434/api/tags"
echo ""
echo " Manage:"
echo "   sudo systemctl status ollama"
echo "   sudo systemctl status coco-web-ui"
echo "   sudo systemctl status nginx"
echo "   sudo systemctl status avahi-daemon"
echo "   ollama list"
echo "   ollama pull <model>"
echo "============================================="
