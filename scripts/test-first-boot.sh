#!/bin/bash

# Test script to verify first boot behavior
# This simulates the first boot WiFi detection logic

echo "=== Testing First Boot WiFi Behavior ==="
echo ""

# Test 1: Check WiFi credential detection
echo "Test 1: WiFi Credential Detection"
echo "--------------------------------"

WIFI_CONFIG_FILE="config/dietpi-wifi.txt"

if [ ! -f "$WIFI_CONFIG_FILE" ]; then
    echo "❌ WiFi config file not found: $WIFI_CONFIG_FILE"
    exit 1
fi

# Extract SSID from config file
ssid=$(grep "aWIFI_SSID\[0\]=" "$WIFI_CONFIG_FILE" | cut -d"'" -f2)

echo "SSID found in config: '$ssid'"

if [ -z "$ssid" ] || [ "$ssid" = "" ]; then
    echo "✅ No WiFi credentials configured - HOTSPOT MODE EXPECTED"
    wifi_configured=false
else
    echo "✅ WiFi credentials found: $ssid - STATION MODE EXPECTED"
    wifi_configured=true
fi

echo ""

# Test 2: Check hostapd configuration
echo "Test 2: Hotspot Configuration"
echo "-----------------------------"

HOSTAPD_CONFIG="config/hostapd.conf"

if [ ! -f "$HOSTAPD_CONFIG" ]; then
    echo "❌ Hostapd config file not found: $HOSTAPD_CONFIG"
    exit 1
fi

hotspot_ssid=$(grep "^ssid=" "$HOSTAPD_CONFIG" | cut -d'=' -f2)
hotspot_pass=$(grep "^wpa_passphrase=" "$HOSTAPD_CONFIG" | cut -d'=' -f2)

echo "✅ Hotspot SSID: $hotspot_ssid"
echo "✅ Hotspot Password: $hotspot_pass"
echo ""

# Test 3: Check mDNS configuration
echo "Test 3: mDNS Configuration"
echo "--------------------------"

AVAHI_CONFIG="config/avahi-daemon.conf"

if [ ! -f "$AVAHI_CONFIG" ]; then
    echo "❌ Avahi config file not found: $AVAHI_CONFIG"
    exit 1
fi

hostname=$(grep "^host-name=" "$AVAHI_CONFIG" | cut -d'=' -f2)
domain=$(grep "^domain-name=" "$AVAHI_CONFIG" | cut -d'=' -f2)

echo "✅ mDNS Hostname: $hostname"
echo "✅ mDNS Domain: $domain"
echo "✅ Device will be accessible at: http://$hostname.$domain"
echo ""

# Test 4: Expected first boot behavior
echo "Test 4: Expected First Boot Behavior"
echo "------------------------------------"

if [ "$wifi_configured" = false ]; then
    echo "🔥 FIRST BOOT SEQUENCE (No WiFi configured):"
    echo "   1. Device boots with DietPi"
    echo "   2. Automation script runs"
    echo "   3. Detects no WiFi credentials"
    echo "   4. Starts WiFi hotspot: $hotspot_ssid"
    echo "   5. Device gets IP: 192.168.4.1"
    echo "   6. mDNS broadcasts: $hostname.$domain → 192.168.4.1"
    echo "   7. Web UI accessible at: http://$hostname.$domain"
    echo ""
    echo "📱 USER EXPERIENCE:"
    echo "   1. User connects phone to WiFi: $hotspot_ssid"
    echo "   2. Phone enters password: $hotspot_pass"
    echo "   3. Phone gets IP in range: 192.168.4.2-20"
    echo "   4. User opens browser to: http://$hostname.$domain"
    echo "   5. Web interface shows WiFi configuration"
else
    echo "🌐 FIRST BOOT SEQUENCE (WiFi configured):"
    echo "   1. Device boots with DietPi"
    echo "   2. Automation script runs"
    echo "   3. Finds WiFi credentials: $ssid"
    echo "   4. Attempts to connect to: $ssid"
    echo "   5. Gets IP from router DHCP"
    echo "   6. mDNS broadcasts: $hostname.$domain → [router IP]"
    echo "   7. Web UI accessible at: http://$hostname.$domain"
    echo ""
    echo "📱 USER EXPERIENCE:"
    echo "   1. User's devices already on same network"
    echo "   2. User opens browser to: http://$hostname.$domain"
    echo "   3. Full Ollama chat interface available"
fi

echo ""
echo "=== Test Summary ==="
echo "✅ All configuration files present"
echo "✅ mDNS configured for $hostname.$domain"
echo "✅ Hotspot configured: $hotspot_ssid / $hotspot_pass"
if [ "$wifi_configured" = false ]; then
    echo "✅ Expected behavior: HOTSPOT MODE on first boot"
else
    echo "✅ Expected behavior: STATION MODE on first boot"
fi
echo ""
echo "Ready for SD card flashing and testing!"
