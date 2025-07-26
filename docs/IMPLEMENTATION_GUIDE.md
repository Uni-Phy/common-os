# Implementation Guide - Common Compute OS with Web UI

## Overview
This guide covers the complete implementation of Common Compute OS with integrated web UI, accessible via `http://coco.local` on mobile devices and browsers.

## Features Implemented

### Core Features
- **mDNS Resolution**: Device accessible at `coco.local` 
- **Web Interface**: NextJS-based UI for Ollama interaction
- **WiFi Configuration**: In-browser WiFi setup capability
- **Automatic Fallback**: WiFi hotspot mode when no credentials configured
- **Mobile Optimized**: Responsive design for mobile devices
- **Zero Configuration**: Plug-and-play experience

### Technical Components
- **Base OS**: DietPi (Debian-based, lightweight)
- **AI Backend**: Ollama server with gemma3:1b model
- **Web Frontend**: Modified nextjs-ollama-llm-ui
- **mDNS Service**: Avahi daemon for local discovery
- **Network Management**: Automatic WiFi/hotspot switching
- **Reverse Proxy**: Nginx for port 80 access

## File Structure
```
common-os/
├── config/
│   ├── Automation_Custom_Script.sh    # Main setup script
│   ├── setup-web-ui.sh               # Web UI installation script
│   ├── dietpi.txt                    # DietPi configuration
│   ├── dietpi-wifi.txt               # WiFi credentials template
│   ├── avahi-daemon.conf             # mDNS configuration
│   ├── coco-web-ui.service           # SystemD service for web UI
│   └── hostapd.conf                  # WiFi hotspot configuration
└── docs/
    ├── web-ui-integration-plan.md     # Detailed architecture plan
    └── IMPLEMENTATION_GUIDE.md        # This file
```

## User Experience Flow

### Initial Setup (No WiFi Configured)
1. **Flash and Boot**: User flashes SD card and powers on Raspberry Pi
2. **Hotspot Mode**: Device creates "CommonCompute-Setup" WiFi network
3. **Mobile Connection**: User connects phone to hotspot (password: `coco1234`)
4. **Web Access**: User opens browser and goes to `http://coco.local`
5. **WiFi Setup**: Web interface shows WiFi configuration screen
6. **Network Switch**: Device connects to home WiFi and disables hotspot
7. **Ready to Use**: Full Ollama chat interface available

### Normal Operation (WiFi Configured)
1. **Auto Connection**: Device boots and connects to configured WiFi
2. **Local Access**: Any device on network can access `http://coco.local`
3. **Full Features**: Complete Ollama chat interface with model management
4. **System Management**: WiFi reconfiguration and system status available

## Installation Process

### Automated Setup
The entire setup is automated through the DietPi first-boot process:

1. **Base System**: DietPi installs and configures base system
2. **User Creation**: Creates 'common' user with sudo privileges
3. **Ollama Installation**: Downloads and configures Ollama server
4. **Web UI Setup**: Clones and builds NextJS application
5. **Network Services**: Configures mDNS, WiFi monitoring, and hotspot
6. **Service Management**: Sets up SystemD services for auto-start

### Manual Steps (for developers)
```bash
# 1. Flash DietPi image to SD card
# 2. Copy config files to boot partition
cp config/* /path/to/sd/card/

# 3. Insert SD card and power on device
# 4. Wait for automatic setup to complete (10-20 minutes)
# 5. Access via http://coco.local
```

## Technical Details

### Network Configuration
- **Primary Interface**: wlan0 (WiFi)
- **Station Mode**: Connects to existing WiFi networks
- **Hotspot Mode**: Creates AP with DHCP (192.168.4.1/24)
- **mDNS**: Broadcasts coco.local on all interfaces
- **Monitoring**: 30-second WiFi status checks

### Service Architecture
```
┌─────────────────────────────────────────┐
│            User Browser                 │ 
│        http://coco.local                │
└─────────────┬───────────────────────────┘
              │ HTTP/80
┌─────────────▼───────────────────────────┐
│         Nginx Reverse Proxy             │
│           (Port 80 → 3000)              │
└─────────────┬───────────────────────────┘
              │ HTTP/3000
┌─────────────▼───────────────────────────┐
│        NextJS Web Application           │
│     (with WiFi config & chat UI)        │
└─────────────┬───────────────────────────┘
              │ HTTP/11434
┌─────────────▼───────────────────────────┐
│          Ollama Server                  │
│      (AI model inference)               │
└─────────────────────────────────────────┘
```

### Security Features
- **Local Network Only**: No external internet exposure
- **Input Validation**: Sanitized form inputs for WiFi configuration
- **Service Isolation**: SystemD security restrictions
- **Firewall Rules**: Only necessary ports open (80, 3000, 11434, 5353)

## Configuration Files

### Key Configuration Details

#### mDNS (Avahi)
- **Hostname**: coco
- **Domain**: local
- **Interfaces**: wlan0, eth0
- **IPv4 Only**: Simplified for compatibility

#### WiFi Hotspot
- **SSID**: CommonCompute-Setup
- **Password**: coco1234
- **Security**: WPA2
- **IP Range**: 192.168.4.2-20

#### Web Services
- **NextJS Port**: 3000
- **Nginx Port**: 80 (reverse proxy)
- **Ollama Port**: 11434
- **User**: common (non-root execution)

## Development and Customization

### Adding Features
The web interface can be extended by:
1. **Modifying UI**: Edit files in `/opt/coco-web-ui/`
2. **Adding APIs**: Create endpoints in `pages/api/`
3. **System Integration**: Add scripts in `/usr/local/bin/`

### Customizing Setup
Before flashing, modify these files:
- `config/dietpi.txt`: System settings
- `config/hostapd.conf`: Hotspot configuration
- `config/setup-web-ui.sh`: Installation process

## Troubleshooting

### Common Issues
1. **mDNS Not Working**: Check Avahi service status
2. **Web UI Not Loading**: Verify NextJS service and port 3000
3. **WiFi Issues**: Check WiFi monitor service and logs
4. **Hotspot Problems**: Verify hostapd configuration

### Log Locations
- **Setup Logs**: `/var/log/coco-setup.log`
- **Ollama Logs**: `journalctl -u ollama`
- **Web UI Logs**: `journalctl -u coco-web-ui`
- **System Logs**: `journalctl -xe`

### Debugging Commands
```bash
# Check service status
systemctl status coco-web-ui ollama avahi-daemon

# Test mDNS resolution
avahi-resolve -n coco.local

# Check network configuration
ip addr show wlan0
iwconfig

# Monitor WiFi status
cat /etc/coco/wifi-status
```

## Next Steps

### Phase 1 - MVP Testing
- [ ] Build and test complete image
- [ ] Verify all services start correctly
- [ ] Test WiFi configuration flow
- [ ] Validate mDNS resolution on multiple devices

### Phase 2 - UI Enhancements
- [ ] Customize NextJS UI for Common Compute branding
- [ ] Add WiFi configuration interface to web app
- [ ] Implement system status dashboard
- [ ] Add model management interface

### Phase 3 - Advanced Features
- [ ] Multiple WiFi network support
- [ ] System backup/restore functionality
- [ ] Advanced security features
- [ ] Performance monitoring and optimization

## Contributing
This implementation follows the principle of simplicity and minimum entropy increase. When adding features:
1. Keep configurations minimal and focused
2. Prefer simple solutions over complex ones
3. Ask for clarity when requirements are ambiguous
4. Maintain backward compatibility where possible

## Support
For issues and feature requests, refer to the project documentation and log files. The system is designed to be self-diagnosing with comprehensive logging.
