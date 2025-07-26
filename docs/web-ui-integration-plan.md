# Web UI Integration Plan - Common Compute OS

## Overview
Create a complete plug-and-play experience where users can:
1. Flash the Common Compute OS image to an SD card
2. Boot their Raspberry Pi
3. Access `http://coco.local` from their mobile phone
4. Configure WiFi credentials through the web interface
5. Use Ollama models immediately without any technical setup

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Common Compute OS Image                      │
├─────────────────────────────────────────────────────────────────┤
│  Base Layer: DietPi (Debian-based)                            │
├─────────────────────────────────────────────────────────────────┤
│  Services Layer:                                               │
│  ├── Ollama Server (0.0.0.0:11434)                           │
│  ├── NextJS Web UI (0.0.0.0:3000)                            │
│  ├── WiFi Hotspot (fallback mode)                            │
│  └── mDNS/Avahi (coco.local resolution)                      │
├─────────────────────────────────────────────────────────────────┤
│  Web Interface Features:                                       │
│  ├── Ollama Chat Interface (from nextjs-ollama-llm-ui)       │
│  ├── WiFi Configuration Panel                                │
│  ├── System Status Dashboard                                 │
│  └── Model Management Interface                              │
└─────────────────────────────────────────────────────────────────┘
```

## Implementation Plan

### Phase 1: Core Infrastructure
1. **mDNS Setup**: Configure Avahi for `coco.local` resolution
2. **WiFi Hotspot**: Setup fallback AP mode when no WiFi configured
3. **Web Server**: Install and configure NextJS application
4. **Service Integration**: Ensure all services start automatically

### Phase 2: Frontend Customization
1. **Clone and Modify**: Fork nextjs-ollama-llm-ui repository
2. **WiFi Configuration UI**: Add WiFi setup components
3. **System Dashboard**: Add device status and configuration panels
4. **Mobile Optimization**: Ensure responsive design for mobile devices

### Phase 3: System Integration
1. **WiFi Management**: Backend APIs for WiFi configuration
2. **Service Orchestration**: Automatic service restart after WiFi changes
3. **Status Monitoring**: Real-time system health monitoring
4. **User Experience**: Smooth onboarding flow

## Technical Requirements

### System Services
- **Ollama**: AI model inference server
- **NextJS**: Web application server
- **Avahi**: mDNS resolution service
- **hostapd**: WiFi hotspot functionality
- **dhcpcd**: DHCP client/server
- **systemd**: Service management

### Network Configuration
- **Primary Mode**: Station mode (connect to existing WiFi)
- **Fallback Mode**: Access Point mode with captive portal
- **mDNS**: `coco.local` domain resolution
- **Port Mapping**: 
  - 3000: Web interface
  - 11434: Ollama API
  - 80: HTTP redirect to 3000

### Storage Requirements
- **Base OS**: ~2GB
- **Web Application**: ~500MB
- **Ollama + Models**: ~2-4GB
- **Total**: ~8GB minimum SD card

## User Experience Flow

### Initial Boot (No WiFi Configured)
1. Device boots and creates WiFi hotspot "CommonCompute-XXXX"
2. User connects mobile device to hotspot
3. Captive portal redirects to `http://coco.local:3000`
4. User sees WiFi configuration screen
5. User enters WiFi credentials and saves
6. Device restarts networking and connects to WiFi
7. User can now access device via home network

### Normal Operation (WiFi Configured)
1. Device boots and connects to configured WiFi
2. User accesses `http://coco.local:3000` from any device on network
3. Full Ollama chat interface is available
4. User can manage models, view system status, reconfigure WiFi

## File Structure
```
common-os/
├── web-ui/                     # NextJS application
│   ├── components/
│   │   ├── chat/              # Ollama chat components
│   │   ├── wifi/              # WiFi configuration
│   │   └── system/            # System status
│   ├── pages/
│   │   ├── api/               # Backend API routes
│   │   ├── setup/             # Initial setup flow
│   │   └── dashboard/         # Main interface
│   └── public/
├── config/
│   ├── web-ui-service.service # SystemD service file
│   ├── avahi-daemon.conf      # mDNS configuration
│   └── hostapd.conf           # WiFi hotspot config
└── scripts/
    ├── setup-web-ui.sh        # Web UI installation
    ├── wifi-manager.sh        # WiFi management script
    └── network-monitor.sh     # Network status monitoring
```

## Security Considerations
- **Local Network Only**: Web interface only accessible on local network
- **No Internet Exposure**: No external access by default
- **WiFi Security**: WPA2/WPA3 for hotspot mode
- **Input Validation**: Sanitize all user inputs
- **Session Management**: Basic session handling for configuration

## Development Phases

### MVP (Minimum Viable Product)
- [ ] Basic NextJS UI with Ollama integration
- [ ] WiFi configuration interface
- [ ] mDNS resolution working
- [ ] Automatic service startup

### Enhanced Features
- [ ] Mobile-optimized interface
- [ ] Advanced model management
- [ ] System monitoring dashboard
- [ ] Multiple WiFi network support
- [ ] Backup/restore functionality

### Future Enhancements
- [ ] Multi-device support
- [ ] Remote management
- [ ] Plugin system
- [ ] Advanced AI features
- [ ] Container support

## Next Steps
1. Set up development environment
2. Clone and customize nextjs-ollama-llm-ui
3. Implement WiFi configuration backend
4. Create system integration scripts
5. Build and test complete image
6. User testing and feedback collection
