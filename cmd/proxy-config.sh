#!/bin/bash
#
# UniPhy Common OS - Ollama Proxy Configuration
# This script installs and configures Nginx to proxy requests to an Ollama instance.

# --- Configuration ---
OLLAMA_HOST="localhost"
OLLAMA_PORT="11434"
PROXY_PORT="8080"

# --- Helper Functions ---

log() {
  echo "[OLLAMA PROXY] $1"
}

check_root() {
  if [ "$(id -u)" -ne 0 ]; then
    log "This script must be run as root. Aborting."
    exit 1
  fi
}

install_nginx() {
  if ! command -v nginx &> /dev/null; then
    log "Nginx not found. Installing..."
    apt-get update
    apt-get install -y nginx
  else
    log "Nginx is already installed."
  fi
}

create_proxy_config() {
  log "Creating Nginx proxy configuration..."
  
  cat << EOF > /etc/nginx/sites-available/ollama-proxy
server {
    listen $PROXY_PORT;
    server_name localhost;

    location / {
        proxy_pass http://$OLLAMA_HOST:$OLLAMA_PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

  log "Nginx configuration file created at /etc/nginx/sites-available/ollama-proxy"
}

enable_proxy_site() {
  log "Enabling Ollama proxy site..."
  
  # Remove default site if it exists
  if [ -L /etc/nginx/sites-enabled/default ]; then
    rm /etc/nginx/sites-enabled/default
  fi
  
  # Enable our new site
  ln -sf /etc/nginx/sites-available/ollama-proxy /etc/nginx/sites-enabled/
  
  log "Ollama proxy site enabled."
}

restart_nginx() {
  log "Restarting Nginx to apply changes..."
  systemctl restart nginx
  log "Nginx restarted successfully."
}

# --- Main Execution ---

check_root
install_nginx
create_proxy_config
enable_proxy_site
restart_nginx

log "Ollama proxy setup complete. You can now access Ollama on port $PROXY_PORT."

