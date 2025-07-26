#!/bin/bash

# Set script to exit on error
set -e

echo "=== Starting Simplified Ollama Setup ==="
echo "$(date): Setup script started" >> /var/log/ollama-setup.log

# Create common user as primary user instead of dietpi
echo "Setting up 'common' as primary user..."

# Create common user if it doesn't exist
if ! id -u common >/dev/null 2>&1; then
    echo "Creating common user..."
    # Create user with home directory and bash shell
    useradd -m -s /bin/bash common
    
    # Get password from dietpi global password setting
    COMMON_PWD=$(grep -oP 'AUTO_SETUP_GLOBAL_PASSWORD=\K.*' /boot/dietpi.txt || echo "ccos123")
    echo "common:${COMMON_PWD}" | chpasswd
    
    # Add to important groups
    usermod -aG sudo,adm,dialout,cdrom,audio,video,plugdev,users,input,netdev,spi,i2c,gpio common
    
    # If dietpi user exists, migrate settings
    if id -u dietpi >/dev/null 2>&1; then
        # Copy important dotfiles
        if [ -d "/home/dietpi" ]; then
            cp -r /home/dietpi/.ssh /home/common/ 2>/dev/null || true
            cp /home/dietpi/.bashrc /home/common/ 2>/dev/null || true
            cp /home/dietpi/.bash_profile /home/common/ 2>/dev/null || true
            chown -R common:common /home/common
        fi
    fi
    
    echo "User 'common' created as primary user" >> /var/log/ollama-setup.log
else
    echo "User 'common' already exists"
fi

# Make common the default autologin user
if grep -q "AUTO_SETUP_AUTOSTART_LOGIN_USER" /boot/dietpi.txt; then
    sed -i 's/AUTO_SETUP_AUTOSTART_LOGIN_USER=.*/AUTO_SETUP_AUTOSTART_LOGIN_USER=common/' /boot/dietpi.txt
fi

# Set PATH and environment for common user
cat > /home/common/.bash_profile << 'EOF'
# ~/.bash_profile for common user

# Set PATH
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Include .bashrc if it exists
if [ -f "$HOME/.bashrc" ]; then
    . "$HOME/.bashrc"
fi
EOF

# Ensure proper ownership
chown common:common /home/common/.bash_profile

# 1. Update and upgrade
echo "Updating and upgrading system..."
apt-get update
apt-get upgrade -y

# 2. CPU Governor Configuration
echo "Configuring CPU governor for optimal performance..."
echo performance | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
echo "CPU governor set to performance" >> /var/log/ollama-setup.log

# 3. Swap Setup - Increase swap for better LLM performance
echo "Configuring swap space..."
CURRENT_SWAP=$(free -m | awk '/^Swap:/ {print $2}')
if [ "$CURRENT_SWAP" -lt 2048 ]; then
    echo "Increasing swap space to 2GB..."
    if [ -f /var/swap ]; then
        swapoff /var/swap
        rm /var/swap
    fi
    fallocate -l 2G /var/swap
    chmod 600 /var/swap
    mkswap /var/swap
    swapon /var/swap
    echo '/var/swap none swap sw 0 0' >> /etc/fstab
    echo "Swap increased to 2GB" >> /var/log/ollama-setup.log
fi

# 4. Install Ollama
echo "Installing Ollama..."
mkdir -p /opt/ollama
curl -fsSL https://ollama.ai/install.sh | sh
echo "Ollama installed" >> /var/log/ollama-setup.log

# 5. Configure Ollama
echo "Configuring Ollama to listen on all interfaces..."
mkdir -p /etc/systemd/system/ollama.service.d/
cat > /etc/systemd/system/ollama.service.d/override.conf << EOF
[Service]
Environment="OLLAMA_HOST=0.0.0.0:11434"
EOF

# Restart Ollama to apply the new configuration
systemctl daemon-reload
systemctl enable ollama
systemctl restart ollama

# Wait for Ollama service to be fully operational
echo "Waiting for Ollama service to start..."
sleep 10

# 6. Pull the lightweight models
echo "Downloading lightweight LLM models..."
ollama pull gemma3:1b
# Optionally pull llama3.2:1b if there's enough space
# ollama pull llama3.2:1b
echo "Models downloaded" >> /var/log/ollama-setup.log

# 7. Configure firewall if UFW is installed
if command -v ufw > /dev/null; then
    echo "Configuring firewall rules..."
    ufw allow ssh
    ufw allow 11434/tcp
    ufw --force enable
    echo "Firewall configured" >> /var/log/ollama-setup.log
fi

# 8. Create helper scripts
echo "Creating helper scripts..."

# Create model management script
cat > /usr/local/bin/ollama-manage << EOF
#!/bin/bash
# Simple script to manage Ollama models

case "\$1" in
    list)
        ollama list
        ;;
    pull)
        if [ -z "\$2" ]; then
            echo "Usage: ollama-manage pull <model_name>"
            exit 1
        fi
        ollama pull "\$2"
        ;;
    remove)
        if [ -z "\$2" ]; then
            echo "Usage: ollama-manage remove <model_name>"
            exit 1
        fi
        ollama rm "\$2"
        ;;
    space)
        du -sh ~/.ollama
        ;;
    *)
        echo "Usage: ollama-manage {list|pull|remove|space}"
        exit 1
esac
EOF
chmod +x /usr/local/bin/ollama-manage

echo "Helper scripts created" >> /var/log/ollama-setup.log

# 9. Setup Web UI and mDNS
echo "Setting up web interface and mDNS..."
if [ -f "/boot/setup-web-ui.sh" ]; then
    chmod +x /boot/setup-web-ui.sh
    /boot/setup-web-ui.sh
    echo "Web UI setup completed" >> /var/log/ollama-setup.log
    
    # Immediately run WiFi management to start hotspot if needed
    echo "Starting initial WiFi management..."
    if [ -f "/usr/local/bin/coco-wifi-manager" ]; then
        /usr/local/bin/coco-wifi-manager auto
        echo "Initial WiFi management completed" >> /var/log/ollama-setup.log
    fi
else
    echo "Web UI setup script not found, skipping..." >> /var/log/ollama-setup.log
fi

# 10. Display connection information
IP_ADDRESS=$(hostname -I | awk '{print $1}')
echo "======================================"
echo "Simplified Ollama Setup Complete!"
echo "======================================"
echo "Ollama API endpoint: http://${IP_ADDRESS}:11434"
echo "Models installed: gemma3:1b"
echo "To manage models: ollama-manage {list|pull|remove|space}"
echo "To use Ollama API: curl http://${IP_ADDRESS}:11434/api/generate -d '{\"model\": \"gemma3:1b\", \"prompt\": \"Hello, how are you?\"}'"
echo "======================================"
echo "$(date): Setup script completed successfully" >> /var/log/ollama-setup.log
