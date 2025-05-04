#!/bin/bash

# Script to copy Common Compute OS configuration files to a USB drive
# Copyright (c) 2025 Common Compute OS
# License: MIT

# Set colors for better user experience
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration files to copy
CONFIG_FILES=(
    "dietpi.txt"
    "dietpi-wifi.txt"
    "Automation_Custom_Script.sh"
)

# Print colorful banner
echo -e "${BLUE}=========================================================${NC}"
echo -e "${BLUE}        Common Compute OS USB Configuration Tool         ${NC}"
echo -e "${BLUE}=========================================================${NC}"
echo

# Function to display usage
usage() {
    echo -e "${YELLOW}Usage:${NC} $0 [options]"
    echo
    echo -e "${YELLOW}Options:${NC}"
    echo "  -h, --help         Show this help message"
    echo "  -d, --dest PATH    Specify destination directory (skips USB detection)"
    echo "  -v, --verbose      Enable verbose output"
    echo
    echo -e "${YELLOW}Description:${NC}"
    echo "  This script copies Common Compute OS configuration files to a USB drive."
    echo "  If no destination is specified, it will detect and list available USB drives."
    echo
}

# Function to detect OS type
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    else
        echo "unknown"
    fi
}

# Function to detect mounted USB drives on macOS
detect_usb_macos() {
    echo -e "${YELLOW}Detecting USB drives...${NC}"
    
    # Find all external, non-internal storage volumes
    local volumes=$(diskutil list | grep -E "external|removable" | grep -v "internal" | grep -v "disk0" | grep -v "(disk" | awk '{print $NF}')
    
    if [ -z "$volumes" ]; then
        echo -e "${RED}No USB drives detected!${NC}"
        echo -e "${YELLOW}Please connect a USB drive and try again.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Found the following USB volumes:${NC}"
    local i=1
    local mounts=()
    
    # For each external disk, find its mounted volumes
    for disk in $volumes; do
        local mounted_paths=$(diskutil info "$disk" | grep "Mount Point" | awk '{print $NF}')
        if [ -n "$mounted_paths" ]; then
            for path in $mounted_paths; do
                if [ -d "$path" ]; then
                    echo "  ${i}. ${path}"
                    mounts[$i]="$path"
                    i=$((i+1))
                fi
            done
        fi
    done
    
    if [ ${#mounts[@]} -eq 0 ]; then
        echo -e "${RED}No mounted USB volumes found!${NC}"
        echo -e "${YELLOW}Please make sure your USB drive is properly mounted.${NC}"
        exit 1
    fi
    
    # Ask user to select a drive
    echo
    echo -e "${YELLOW}Which drive would you like to use?${NC} (Enter a number)"
    read -r selection
    
    # Validate input
    if ! [[ "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -gt ${#mounts[@]} ]; then
        echo -e "${RED}Invalid selection!${NC}"
        exit 1
    fi
    
    # Return the selected mount point
    echo "${mounts[$selection]}"
}

# Function to detect mounted USB drives on Linux
detect_usb_linux() {
    echo -e "${YELLOW}Detecting USB drives...${NC}"
    
    # Use lsblk to find removable block devices and their mount points
    local mounts=$(lsblk -o NAME,RM,MOUNTPOINT | grep '1' | grep -v "sd[a-z][0-9]" | awk '$3 != "" {print $3}' | grep -v '^$')
    
    if [ -z "$mounts" ]; then
        echo -e "${RED}No USB drives detected!${NC}"
        echo -e "${YELLOW}Please connect a USB drive and try again.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Found the following USB volumes:${NC}"
    local i=1
    local mount_array=()
    
    # Display the mount points
    while IFS= read -r mount; do
        echo "  ${i}. ${mount}"
        mount_array[$i]="$mount"
        i=$((i+1))
    done <<< "$mounts"
    
    # Ask user to select a drive
    echo
    echo -e "${YELLOW}Which drive would you like to use?${NC} (Enter a number)"
    read -r selection
    
    # Validate input
    if ! [[ "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -gt ${#mount_array[@]} ]; then
        echo -e "${RED}Invalid selection!${NC}"
        exit 1
    fi
    
    # Return the selected mount point
    echo "${mount_array[$selection]}"
}

# Function to copy files to destination
copy_files() {
    local destination="$1"
    local boot_dir="${destination}/boot"
    
    echo -e "${YELLOW}Copying configuration files to ${boot_dir}...${NC}"
    
    # Make sure the boot directory exists
    if [ ! -d "$boot_dir" ]; then
        echo -e "${YELLOW}Creating boot directory...${NC}"
        mkdir -p "$boot_dir"
        if [ $? -ne 0 ]; then
            echo -e "${RED}Error: Failed to create boot directory!${NC}"
            return 1
        fi
    fi
    
    # Copy each file
    local success=true
    for file in "${CONFIG_FILES[@]}"; do
        if [ -f "$file" ]; then
            echo -e "  Copying ${file}..."
            cp "$file" "${boot_dir}/" 
            if [ $? -ne 0 ]; then
                echo -e "${RED}  Error: Failed to copy ${file}!${NC}"
                success=false
            else
                # Verify file was copied successfully
                if [ -f "${boot_dir}/${file}" ]; then
                    # Check if the file sizes match
                    local src_size=$(wc -c < "$file")
                    local dst_size=$(wc -c < "${boot_dir}/${file}")
                    if [ "$src_size" -eq "$dst_size" ]; then
                        echo -e "${GREEN}  Successfully copied ${file} (${src_size} bytes)${NC}"
                    else
                        echo -e "${RED}  Error: File size mismatch for ${file}!${NC}"
                        echo -e "${RED}  Source: ${src_size} bytes, Destination: ${dst_size} bytes${NC}"
                        success=false
                    fi
                else
                    echo -e "${RED}  Error: ${file} not found in destination!${NC}"
                    success=false
                fi
            fi
        else
            echo -e "${RED}  Error: ${file} not found in source directory!${NC}"
            success=false
        fi
    done
    
    # Return success or failure
    if $success; then
        return 0
    else
        return 1
    fi
}

# Function to confirm before proceeding
confirm() {
    echo -e "${YELLOW}Are you sure you want to copy the configuration files to the selected drive?${NC} (y/n)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo -e "${RED}Operation cancelled by user.${NC}"
        exit 0
    fi
}

# Parse command line arguments
verbose=false
custom_dest=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            exit 0
            ;;
        -d|--dest)
            custom_dest="$2"
            shift 2
            ;;
        -v|--verbose)
            verbose=true
            shift
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            usage
            exit 1
            ;;
    esac
done

# Main execution flow
os_type=$(detect_os)

if [ -n "$custom_dest" ]; then
    # Use custom destination if provided
    if [ ! -d "$custom_dest" ]; then
        echo -e "${RED}Error: Destination directory does not exist!${NC}"
        exit 1
    fi
    confirm
    if copy_files "$custom_dest"; then
        echo -e "${GREEN}Configuration files successfully copied to ${custom_dest}/boot${NC}"
        echo -e "${BLUE}=========================================================${NC}"
        echo -e "${BLUE}                  Operation completed!                   ${NC}"
        echo -e "${BLUE}=========================================================${NC}"
        exit 0
    else
        echo -e "${RED}Failed to copy all configuration files!${NC}"
        exit 1
    fi
else
    # Detect USB drives based on OS type
    if [ "$os_type" == "macos" ]; then
        dest=$(detect_usb_macos)
    elif [ "$os_type" == "linux" ]; then
        dest=$(detect_usb_linux)
    else
        echo -e "${RED}Unsupported operating system: ${os_type}${NC}"
        echo -e "${YELLOW}Please specify a destination directory using the -d option.${NC}"
        exit 1
    fi
    
    # Confirm and copy files
    if [ -n "$dest" ]; then
        echo -e "${GREEN}Selected USB drive: ${dest}${NC}"
        confirm
        if copy_files "$dest"; then
            echo -e "${GREEN}Configuration files successfully copied to ${dest}/boot${NC}"
            echo -e "${BLUE}=========================================================${NC}"
            echo -e "${BLUE}                  Operation completed!                   ${NC}"
            echo -e "${BLUE}=========================================================${NC}"
            exit 0
        else
            echo -e "${RED}Failed to copy all configuration files!${NC}"
            exit 1
        fi
    else
        echo -e "${RED}No USB drive selected!${NC}"
        exit 1
    fi
fi

