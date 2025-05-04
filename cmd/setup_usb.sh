#!/bin/bash

# ======================================================
# Common Compute OS - USB Setup Utility
# ======================================================
#
# This script automates the process of configuring a USB drive with
# Common Compute OS configuration files and WiFi credentials.
#
# Functions:
# - Detects USB drives connected to the system
# - Allows user to select a target drive
# - Collects WiFi credentials
# - Updates dietpi-wifi.txt with provided credentials
# - Copies configuration files to the USB drive
#
# ======================================================

# Text formatting
BOLD="\033[1m"
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
CYAN="\033[36m"
RESET="\033[0m"

# Config source directory
CONFIG_DIR="../config"

# Print banner
echo -e "${BOLD}${CYAN}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║              Common Compute OS - USB Setup                 ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${RESET}"

# Function to print formatted messages
print_status() {
    local type=$1
    local message=$2
    
    case $type in
        "info")
            echo -e "${CYAN}[INFO]${RESET} $message"
            ;;
        "success")
            echo -e "${GREEN}[SUCCESS]${RESET} $message"
            ;;
        "error")
            echo -e "${RED}[ERROR]${RESET} $message"
            ;;
        "warning")
            echo -e "${YELLOW}[WARNING]${RESET} $message"
            ;;
    esac
}

# Function to detect USB drives
detect_usb_drives() {
    print_status "info" "Detecting USB drives..."
    
    # Get a list of volumes that are likely to be external drives
    # Filter out common system volumes on macOS
    local volumes=()
    local excluded_volumes=("Macintosh HD" "System" "Time Machine" "Recovery" "Preboot")
    
    for vol in /Volumes/*; do
        vol_name=$(basename "$vol")
        is_excluded=false
        
        # Check if the volume is in the excluded list
        for excluded in "${excluded_volumes[@]}"; do
            if [[ "$vol_name" == *"$excluded"* ]]; then
                is_excluded=true
                break
            fi
        done
        
        # Add non-excluded volumes to the list
        if [ "$is_excluded" = false ]; then
            volumes+=("$vol")
        fi
    done
    
    if [ ${#volumes[@]} -eq 0 ]; then
        print_status "error" "No USB drives found! Please insert a USB drive and try again."
        exit 1
    fi
    
    echo -e "\n${BOLD}Available USB drives:${RESET}"
    
    # Display available drives
    for i in "${!volumes[@]}"; do
        local vol="${volumes[$i]}"
        local vol_name=$(basename "$vol")
        local vol_size=$(df -h "$vol" | tail -1 | awk '{print $2}')
        local vol_used=$(df -h "$vol" | tail -1 | awk '{print $5}')
        
        echo -e "  ${BOLD}$((i+1))${RESET}. $vol_name (Size: $vol_size, Used: $vol_used)"
    done
    
    # Ask user to select a drive
    local selected_index
    echo ""
    while true; do
        read -p "Select a drive (1-${#volumes[@]}): " selected_index
        
        # Validate input
        if ! [[ "$selected_index" =~ ^[0-9]+$ ]] || [ "$selected_index" -lt 1 ] || [ "$selected_index" -gt ${#volumes[@]} ]; then
            print_status "error" "Invalid selection. Please enter a number between 1 and ${#volumes[@]}."
        else
            break
        fi
    done
    
    # Return the selected volume
    echo "${volumes[$((selected_index-1))]}"
}

# Function to get WiFi credentials
get_wifi_credentials() {
    echo -e "\n${BOLD}WiFi Configuration${RESET}"
    echo "Please enter your WiFi credentials:"
    
    # Get SSID with validation
    while true; do
        read -p "WiFi SSID: " wifi_ssid
        
        if [ -z "$wifi_ssid" ]; then
            print_status "error" "SSID cannot be empty. Please try again."
        else
            break
        fi
    done
    
    # Get password
    read -p "WiFi Password: " wifi_password
    
    # Create a temporary file with the credentials
    echo "SSID: $wifi_ssid"
    echo "Password: $wifi_password"
    
    # Confirm the credentials
    echo ""
    read -p "Are these credentials correct? (y/n): " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        print_status "info" "Let's try again."
        get_wifi_credentials
    fi
    
    # Return the credentials
    echo "$wifi_ssid|$wifi_password"
}

# Function to update WiFi configuration
update_wifi_config() {
    local usb_drive=$1
    local credentials=$2
    
    # Extract SSID and password
    local wifi_ssid=$(echo "$credentials" | cut -d'|' -f1)
    local wifi_password=$(echo "$credentials" | cut -d'|' -f2)
    
    print_status "info" "Updating WiFi configuration..."
    
    # Create temporary copy of dietpi-wifi.txt
    local temp_config=$(mktemp)
    cp "$CONFIG_DIR/dietpi-wifi.txt" "$temp_config"
    
    # Update WiFi credentials in the file
    sed -i.bak "s/aWIFI_SSID\[0\]=''/aWIFI_SSID\[0\]='$wifi_ssid'/" "$temp_config"
    sed -i.bak "s/aWIFI_KEY\[0\]=''/aWIFI_KEY\[0\]='$wifi_password'/" "$temp_config"
    
    # Clean up backup files
    rm -f "$temp_config.bak"
    
    # Return the temporary file path
    echo "$temp_config"
}

# Function to copy configuration files to USB drive
copy_config_files() {
    local usb_drive=$1
    local temp_wifi_config=$2
    
    print_status "info" "Copying configuration files to USB drive..."
    
    # Create or ensure destination directory exists
    if [ ! -d "$usb_drive" ]; then
        print_status "error" "USB drive directory not found: $usb_drive"
        exit 1
    fi
    
    # First copy all standard config files
    for file in "$CONFIG_DIR"/*; do
        if [ -f "$file" ]; then
            file_name=$(basename "$file")
            
            # Skip dietpi-wifi.txt as we'll use our modified version
            if [ "$file_name" != "dietpi-wifi.txt" ]; then
                cp -f "$file" "$usb_drive/$file_name" || {
                    print_status "error" "Failed to copy $file_name to USB drive. Check permissions."
                    exit 1
                }
                print_status "info" "Copied $file_name to USB drive."
            fi
        fi
    done
    
    # Now copy the modified WiFi config
    cp -f "$temp_wifi_config" "$usb_drive/dietpi-wifi.txt" || {
        print_status "error" "Failed to copy WiFi configuration to USB drive. Check permissions."
        exit 1
    }
    print_status "info" "Copied WiFi configuration to USB drive."
    
    # Clean up temp file
    rm -f "$temp_wifi_config"
    
    return 0
}

# Main process
main() {
    # Check if config directory exists
    if [ ! -d "$CONFIG_DIR" ]; then
        print_status "error" "Config directory not found: $CONFIG_DIR"
        print_status "info" "Please run this script from the cmd directory."
        exit 1
    fi
    
    # Detect and select USB drive
    local selected_drive=$(detect_usb_drives)
    print_status "info" "Selected drive: $(basename "$selected_drive")"
    
    # Get WiFi credentials
    local credentials=$(get_wifi_credentials)
    
    # Update WiFi configuration
    local temp_wifi_config=$(update_wifi_config "$selected_drive" "$credentials")
    
    # Copy configuration files to USB drive
    copy_config_files "$selected_drive" "$temp_wifi_config"
    
    # Display success message
    echo ""
    print_status "success" "USB drive configuration complete!"
    print_status "info" "The following files have been copied to $(basename "$selected_drive"):"
    ls -1 "$CONFIG_DIR" | sed 's/^/  - /'
    
    echo ""
    print_status "info" "WiFi credentials have been configured."
    print_status "info" "You can now safely eject the USB drive and use it with your Common Compute OS device."
    
    # Instructions for next steps
    echo -e "\n${BOLD}Next steps:${RESET}"
    echo "1. Safely eject the USB drive"
    echo "2. Insert the USB drive into your Common Compute OS device"
    echo "3. Power on the device and wait for it to boot"
    echo "4. The device will automatically connect to your WiFi network"
    
    echo ""
    print_status "info" "Thank you for using Common Compute OS!"
}

# Execute the main function
main

