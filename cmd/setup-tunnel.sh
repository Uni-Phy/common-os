#!/bin/bash
#
# Common Compute OS - Cloudflare Tunnel Setup
# This script installs and configures cloudflared to create a persistent,
# secure tunnel from a public URL to the local Ollama proxy.

# --- Prerequisites ---
# 1. A Cloudflare account.
# 2. A domain name added to your Cloudflare account.

# --- Helper Functions ---
log() {
  echo "[TUNNEL SETUP] $1"
}

check_root() {
  if [ "$(id -u)" -ne 0 ]; then
    log "This script must be run as root. Please use sudo. Aborting."
    exit 1
  fi
}

# --- Main Logic ---

install_cloudflared() {
  if command -v cloudflared &> /dev/null; then
    log "`cloudflared --version` is already installed."
    return
  fi
  log "Installing Cloudflare Tunnel daemon (cloudflared)..."
  
  # Detect architecture
  ARCH=$(dpkg --print-architecture)
  case "$ARCH" in
    armhf)
      URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm"
      ;;
    arm64)
      URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64"
      ;;
    amd64)
      URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64"
      ;;
    *)
      log "Unsupported architecture: $ARCH. Please install cloudflared manually."
      exit 1
      ;;
  esac
  
  wget -q "$URL" -O /usr/local/bin/cloudflared
  chmod +x /usr/local/bin/cloudflared
  log "`cloudflared --version` installed successfully."
}

authenticate() {
  log "Authenticating with Cloudflare..."
  log "A browser window will open. Please log in to your Cloudflare account and authorize the domain you want to use."
  
  # The cert.pem file will be created in ~/.cloudflared/ by this command
  cloudflared tunnel login
  
  if [ ! -f ~/.cloudflared/cert.pem ]; then
      log "Authentication failed. cert.pem not found. Please try again."
      exit 1
  fi
  log "Authentication successful."
}

create_tunnel() {
  TUNNEL_NAME="common-compute-ollama"
  
  log "Checking for existing tunnel named '$TUNNEL_NAME'..."
  TUNNEL_ID=$(cloudflared tunnel list | grep "$TUNNEL_NAME" | awk '{print $1}')

  if [ -n "$TUNNEL_ID" ]; then
      log "Tunnel '$TUNNEL_NAME' already exists with ID: $TUNNEL_ID."
  else
      log "Creating new tunnel: $TUNNEL_NAME"
      # The output of this command contains the tunnel ID
      TUNNEL_ID=$(cloudflared tunnel create $TUNNEL_NAME | grep -o '[a-f0-9-]\{36\}')
      if [ -z "$TUNNEL_ID" ]; then
          log "Failed to create tunnel. Aborting."
          exit 1
      fi
      log "Tunnel created with ID: $TUNNEL_ID"
  fi
  
  # Store for later steps
  export TUNNEL_ID
}

create_config_file() {
  log "Creating tunnel configuration file..."
  
  CONFIG_DIR=/etc/cloudflared
  mkdir -p $CONFIG_DIR
  
  cat << EOF > $CONFIG_DIR/config.yml
tunnel: $TUNNEL_ID
credentials-file: /root/.cloudflared/$TUNNEL_ID.json

ingress:
  - hostname: ollama.$USER_DOMAIN
    service: http://localhost:8080
  # Catch-all rule
  - service: http_status:404
EOF

  log "Configuration file created at $CONFIG_DIR/config.yml"
  log "IMPORTANT: Make sure 'ollama.$USER_DOMAIN' is a valid DNS record in your Cloudflare account."
}

setup_dns_and_run() {
  log "Setting up DNS route for the tunnel..."
  cloudflared tunnel route dns $TUNNEL_ID ollama.$USER_DOMAIN
  
  log "DNS route created. Your Ollama instance will be available at https://ollama.$USER_DOMAIN"
  
  log "Installing and starting the cloudflared service..."
  cloudflared service install
  systemctl enable cloudflared
  systemctl start cloudflared
  
  log "Cloudflared service started."
}

# --- Script Execution ---

check_root

log "This script will set up a secure tunnel to expose your local Ollama service."
read -p "Please enter the domain you have configured in Cloudflare (e.g., example.com): " USER_DOMAIN

if [ -z "$USER_DOMAIN" ]; then
    log "Domain name cannot be empty. Aborting."
    exit 1
fi

export USER_DOMAIN

install_cloudflared
authenticate
create_tunnel
create_config_file
setup_dns_and_run

log "✅ Setup complete!"
log "Your Ollama instance should be accessible at: https://ollama.$USER_DOMAIN"
log "You can check the tunnel status with: systemctl status cloudflared"
