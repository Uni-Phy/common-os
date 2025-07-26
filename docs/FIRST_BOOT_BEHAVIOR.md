# First Boot WiFi Behavior - Common Compute OS

## Expected Device Behavior

### Scenario: Fresh SD Card with No WiFi Configured

When you flash the Common Compute OS image and boot it for the first time:

```
┌─────────────────────────────────────────────────────────────────┐
│                    FIRST BOOT SEQUENCE                         │
└─────────────────────────────────────────────────────────────────┘

1. ⚡ Device Powers On
   ├── DietPi base system loads
   ├── Creates 'common' user
   └── Starts initial services

2. 📡 Network Detection Phase
   ├── Checks dietpi-wifi.txt for WiFi credentials
   ├── Finds empty/default WiFi configuration
   └── Determines: NO WIFI CONFIGURED

3. 🔥 Hotspot Mode Activation
   ├── Configures wlan0 interface for AP mode
   ├── Starts WiFi hotspot: "CommonCompute-Setup"
   ├── Password: "coco1234"
   ├── IP Address: 192.168.4.1
   └── DHCP Range: 192.168.4.2 - 192.168.4.20

4. 🌐 Services Startup
   ├── Ollama server starts (localhost:11434)
   ├── NextJS web UI starts (0.0.0.0:3000)
   ├── Nginx reverse proxy (port 80 → 3000)
   ├── Avahi mDNS broadcasts "coco.local"
   └── dnsmasq provides DHCP + DNS resolution

5. ✅ Ready State
   ├── WiFi hotspot broadcasting
   ├── Web interface accessible
   └── Waiting for user configuration
```

## User Experience Flow

### Step 1: Connect to Hotspot
```
📱 Mobile Phone WiFi Settings
├── Scan for Networks
├── See: "CommonCompute-Setup"
├── Connect with password: "coco1234"
└── Phone gets IP: 192.168.4.x
```

### Step 2: Access Web Interface
```
📱 Mobile Browser
├── Open browser
├── Type: "coco.local" or "192.168.4.1"
├── Web interface loads
└── Shows WiFi configuration screen
```

### Step 3: Configure WiFi
```
🌐 Web Interface
├── WiFi Setup Page displays
├── Shows available networks
├── User selects home WiFi
├── Enters password
└── Clicks "Connect"
```

### Step 4: Network Transition
```
🔄 Device Behavior
├── Saves WiFi credentials to dietpi-wifi.txt
├── Stops hotspot mode
├── Connects to home WiFi
├── Gets new IP from router
└── Continues to broadcast coco.local
```

## Technical Implementation Details

### WiFi Status Detection Logic
The device uses this logic to determine when to start hotspot mode:

```bash
# Check if WiFi credentials exist
if grep -q "aWIFI_SSID\[0\]=''" /boot/dietpi-wifi.txt; then
    # No SSID configured - start hotspot
    start_hotspot_mode
else
    # Try to connect to configured WiFi
    attempt_wifi_connection
    if connection_failed; then
        # Fallback to hotspot after timeout
        start_hotspot_mode
    fi
fi
```

### Hotspot Configuration Details
```
Network Name: CommonCompute-Setup
Password: coco1234
Security: WPA2
Channel: 7
IP Address: 192.168.4.1/24
DHCP Range: 192.168.4.2 - 192.168.4.20
DNS Server: 192.168.4.1 (device itself)
```

### mDNS Resolution
```
Local Domain: coco.local
Resolves to: 192.168.4.1 (in hotspot mode)
Services: HTTP (port 80), Ollama API (port 11434)
```

## Potential Issues and Solutions

### Issue 1: mDNS Not Working on Some Phones
**Problem**: Some Android phones don't resolve .local domains
**Solution**: Provide fallback IP access
```
Web Interface Message:
"If coco.local doesn't work, try: http://192.168.4.1"
```

### Issue 2: WiFi Hotspot Not Broadcasting
**Possible Causes**:
- WiFi adapter doesn't support AP mode
- Country code mismatch
- Channel conflicts

**Debug Steps**:
```bash
# Check hostapd status
systemctl status hostapd

# Check WiFi adapter capabilities
iw list | grep -A 10 "Supported interface modes"

# Check logs
journalctl -u hostapd
```

### Issue 3: Web Interface Not Loading
**Possible Causes**:
- NextJS service not started
- Port conflicts
- Firewall blocking connections

**Debug Steps**:
```bash
# Check web service
systemctl status coco-web-ui

# Check port availability
netstat -tulpn | grep :3000
netstat -tulpn | grep :80

# Test local access
curl http://localhost:3000
```

## Improved Implementation

Let me create an enhanced WiFi management script that ensures proper hotspot behavior:
