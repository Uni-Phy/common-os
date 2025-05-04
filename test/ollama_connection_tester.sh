#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RESET='\033[0m'

# Initial server settings
current_server="192.168.1.166"
current_port="11434"
current_protocol="http"

# Function to display the header
show_header() {
  echo -e "${BLUE}============================================${RESET}"
  echo -e "${BLUE}      Ollama API Connection Tester          ${RESET}"
  echo -e "${BLUE}============================================${RESET}"
  echo
}

# Function to test the connection
test_connection() {
  local server="$1"
  local port="$2"
  local protocol="$3"
  local api_url="${protocol}://${server}:${port}/api"
  
  echo -e "${YELLOW}Testing connection to ${api_url}/tags...${RESET}"
  
  # Try to connect with a 5 second timeout
  if curl -s --connect-timeout 5 "${api_url}/tags" > /dev/null; then
    echo -e "${GREEN}✓ Connection successful!${RESET}"
    echo -e "API URL: ${BLUE}${api_url}${RESET}"
    echo
    return 0
  else
    echo -e "${RED}✗ Could not connect to Ollama server at ${api_url}${RESET}"
    return 1
  fi
}

# Function to check connectivity details
check_details() {
  local server="$1"
  local port="$2"
  
  echo -e "${YELLOW}Checking network connectivity:${RESET}"
  
  # Check if server is reachable via ping
  echo -e "- Testing if server ${server} is reachable..."
  if ping -c 1 -W 2 "$server" > /dev/null 2>&1; then
    echo -e "  ${GREEN}✓ Server is reachable (ping successful)${RESET}"
  else
    echo -e "  ${RED}✗ Server is not reachable (ping failed)${RESET}"
    echo -e "  - Check if the IP address is correct"
    echo -e "  - Check if the server is online"
    return 1
  fi
  
  # Check if port is open
  echo -e "- Testing if port ${port} is open on ${server}..."
  if nc -z -w 2 "$server" "$port" 2>/dev/null; then
    echo -e "  ${GREEN}✓ Port is open${RESET}"
  else
    echo -e "  ${RED}✗ Port ${port} is closed on ${server}${RESET}"
    echo -e "  - Check if Ollama is running on the server"
    echo -e "  - Check if Ollama is configured to listen on all interfaces (not just localhost)"
    echo -e "  - Check if a firewall is blocking the connection"
    return 1
  fi
  
  echo -e "${GREEN}- Basic connectivity checks passed${RESET}"
  return 0
}

# Function to present options for fixing the connection
show_fix_options() {
  echo -e "\n${YELLOW}Connection failed. What would you like to do?${RESET}"
  echo -e "1. Try a different server address"
  echo -e "2. Try a different port"
  echo -e "3. Try HTTPS instead of HTTP"
  echo -e "4. Try connecting to localhost"
  echo -e "5. Check connection details"
  echo -e "6. Exit"
  
  read -r -p "Enter your choice (1-6): " choice
  
  case $choice in
    1)
      read -r -p "Enter the new server address: " new_server
      current_server="$new_server"
      test_connection "$current_server" "$current_port" "$current_protocol"
      ;;
    2)
      read -r -p "Enter the port number: " new_port
      current_port="$new_port"
      test_connection "$current_server" "$current_port" "$current_protocol"
      ;;
    3)
      current_protocol="https"
      test_connection "$current_server" "$current_port" "$current_protocol"
      ;;
    4)
      current_server="localhost"
      test_connection "$current_server" "$current_port" "$current_protocol"
      ;;
    5)
      check_details "$current_server" "$current_port"
      ;;
    6)
      echo -e "${BLUE}Exiting...${RESET}"
      exit 0
      ;;
    *)
      echo -e "${RED}Invalid choice. Please try again.${RESET}"
      ;;
  esac
}

# Function to update the API scripts with the new server details
update_api_scripts() {
  local old_url="http://192.168.1.166:11434/api"
  local new_url="${current_protocol}://${current_server}:${current_port}/api"
  
  echo -e "\n${YELLOW}Would you like to update your API scripts with the new connection details? (y/n)${RESET}"
  read -r response
  
  if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo -e "${YELLOW}Updating scripts...${RESET}"
    
    # Update the improved_ollama_api.sh script if it exists
    if [ -f "improved_ollama_api.sh" ]; then
      sed -i.bak "s|${old_url}|${new_url}|g" "improved_ollama_api.sh"
      echo -e "${GREEN}✓ Updated improved_ollama_api.sh${RESET}"
    fi
    
    # Update the ollama_api_examples.sh script if it exists
    if [ -f "ollama_api_examples.sh" ]; then
      sed -i.bak "s|${old_url}|${new_url}|g" "ollama_api_examples.sh"
      echo -e "${GREEN}✓ Updated ollama_api_examples.sh${RESET}"
    fi
    
    echo -e "${GREEN}Scripts updated to use: ${new_url}${RESET}"
    echo -e "Backup files were created with .bak extension"
  fi
}

# Main function
main() {
  show_header
  
  if test_connection "$current_server" "$current_port" "$current_protocol"; then
    echo -e "${GREEN}Connection successful!${RESET}"
    echo -e "You can now use your Ollama API scripts with this connection."
    update_api_scripts
  else
    # Try localhost as a quick fallback
    echo -e "\n${YELLOW}Trying localhost as a fallback...${RESET}"
    if test_connection "localhost" "$current_port" "$current_protocol"; then
      echo -e "${GREEN}Connection to localhost successful!${RESET}"
      current_server="localhost"
      update_api_scripts
    else
      echo -e "${RED}Failed to connect to both remote server and localhost${RESET}"
      check_details "$current_server" "$current_port"
      
      # Keep showing options until user chooses to exit
      while true; do
        show_fix_options
        
        # If we established a successful connection, break the loop
        if [ $? -eq 0 ]; then
          update_api_scripts
          break
        fi
      done
    fi
  fi
}

# Run the main function
main
