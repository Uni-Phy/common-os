#!/bin/bash

# Common Compute OS - Web UI Setup Script
# This script installs and configures the web interface with WiFi management

set -e

echo "=== Setting up Common Compute OS Web UI ==="
echo "$(date): Web UI setup started" >> /var/log/coco-setup.log

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RESET='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${RESET} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${RESET} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${RESET} $1"
}

# 1. Install Node.js and npm
print_status "Installing Node.js and npm..."
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs
print_success "Node.js $(node --version) installed"

# 2. Install system dependencies
print_status "Installing system dependencies..."
apt-get update
apt-get install -y \
    avahi-daemon \
    avahi-utils \
    hostapd \
    dnsmasq \
    git \
    build-essential \
    python3-dev

print_success "System dependencies installed"

# 3. Configure mDNS (Avahi)
print_status "Configuring mDNS for coco.local..."
cp /boot/avahi-daemon.conf /etc/avahi/avahi-daemon.conf
systemctl enable avahi-daemon
systemctl restart avahi-daemon
print_success "mDNS configured - device will be accessible at coco.local"

# 4. Set hostname
print_status "Setting hostname to coco..."
echo "coco" > /etc/hostname
hostnamectl set-hostname coco
print_success "Hostname set to coco"

# 5. Clone and setup web UI
print_status "Setting up web interface..."
cd /opt
git clone https://github.com/jakobhoeg/nextjs-ollama-llm-ui.git coco-web-ui
cd coco-web-ui

# Install dependencies
print_status "Installing web UI dependencies..."
npm install

# Build the application
print_status "Building web application..."
npm run build

# 6. Configure web UI service
print_status "Setting up web UI service..."
cp /boot/coco-web-ui.service /etc/systemd/system/
chown -R common:common /opt/coco-web-ui
systemctl daemon-reload
systemctl enable coco-web-ui

# 7. Setup WiFi management
print_status "Setting up WiFi management..."

# Create WiFi status directory
mkdir -p /etc/coco
echo "unconfigured" > /etc/coco/wifi-status

# Setup hotspot configuration
cp /boot/hostapd.conf /etc/hostapd/hostapd.conf

# Configure dnsmasq for hotspot
cat > /etc/dnsmasq.d/hotspot.conf << EOF
# Configuration for WiFi hotspot
interface=wlan0
dhcp-range=192.168.4.2,192.168.4.20,255.255.255.0,24h
address=/coco.local/192.168.4.1
EOF

# 8. Install enhanced WiFi management
print_status "Installing enhanced WiFi management..."

# Copy the enhanced WiFi manager
cp /boot/wifi-manager.sh /usr/local/bin/coco-wifi-manager
chmod +x /usr/local/bin/coco-wifi-manager

# Create backwards compatibility symlink
ln -sf /usr/local/bin/coco-wifi-manager /usr/local/bin/coco-wifi-check

# Create systemd service for WiFi monitoring
cat > /etc/systemd/system/coco-wifi-monitor.service << EOF
[Unit]
Description=Common Compute OS WiFi Monitor
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/coco-wifi-check
User=root

[Install]
WantedBy=multi-user.target
EOF

# Create timer for regular WiFi checks
cat > /etc/systemd/system/coco-wifi-monitor.timer << EOF
[Unit]
Description=Run WiFi monitor every 30 seconds
Requires=coco-wifi-monitor.service

[Timer]
OnBootSec=30sec
OnUnitActiveSec=30sec
Unit=coco-wifi-monitor.service

[Install]
WantedBy=timers.target
EOF

systemctl daemon-reload
systemctl enable coco-wifi-monitor.timer
systemctl start coco-wifi-monitor.timer

# 9. Configure nginx as reverse proxy (optional, for port 80 access)
print_status "Setting up nginx reverse proxy..."
apt-get install -y nginx

cat > /etc/nginx/sites-available/coco-web-ui << EOF
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    
    server_name coco.local _;
    
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF

# Remove default nginx site and enable our site
rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/coco-web-ui /etc/nginx/sites-enabled/
systemctl enable nginx
systemctl restart nginx

print_success "Nginx reverse proxy configured"

# 10. Start services
print_status "Starting web UI service..."
systemctl start coco-web-ui
print_success "Web UI service started"

# 11. Configure firewall
print_status "Configuring firewall..."
if command -v ufw > /dev/null; then
    ufw allow 80/tcp
    ufw allow 3000/tcp
    ufw allow 5353/udp  # mDNS
    print_success "Firewall configured"
fi

# 12. Final status check
print_status "Checking service status..."
if systemctl is-active --quiet coco-web-ui; then
    print_success "Web UI service is running"
else
    print_error "Web UI service failed to start"
fi

if systemctl is-active --quiet avahi-daemon; then
    print_success "mDNS service is running"
else
    print_error "mDNS service failed to start"
fi

# Display completion message
IP_ADDRESS=$(hostname -I | awk '{print $1}')
echo ""
echo "============================================="
echo "Common Compute OS Web UI Setup Complete!"
echo "============================================="
echo "Access your device at:"
echo "  - http://coco.local (recommended)"
echo "  - http://${IP_ADDRESS}"
echo ""
echo "Default hotspot (if no WiFi configured):"
echo "  - SSID: CommonCompute-Setup"
echo "  - Password: coco1234"
echo "============================================="

echo "$(date): Web UI setup completed successfully" >> /var/log/coco-setup.log
