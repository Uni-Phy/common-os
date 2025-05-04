#!/bin/bash

# Base URL - Update this to match your Ollama server location
API_URL="http://192.168.1.166:11434/api"

# Function to test connectivity before running examples
test_connection() {
  echo "Testing connection to Ollama server at ${API_URL}..."
  if curl -s --connect-timeout 5 "${API_URL}/tags" > /dev/null; then
    echo "✓ Connection successful!"
    return 0
  else
    echo "✗ Could not connect to Ollama server at ${API_URL}"
    echo "Please check that:"
    echo "  1. The server is running at the specified IP address"
    echo "  2. Ollama is running and listening on port 11434"
    echo "  3. There are no firewall rules blocking the connection"
    return 1
  fi
}

# Example 1: List models
list_models() {
  echo -e "\nListing available models..."
  curl -s "${API_URL}/tags" | jq 2>/dev/null || curl -s "${API_URL}/tags"
}

# Example 2: Generate text (non-streaming)
generate_text() {
  echo -e "\nGenerating text with gemma3:1b..."
  curl -s "${API_URL}/generate" \
    -H "Content-Type: application/json" \
    -d '{
      "model": "gemma3:1b",
      "prompt": "Write a short poem about AI",
      "stream": false
    }' | jq 2>/dev/null || curl -s "${API_URL}/generate" \
    -H "Content-Type: application/json" \
    -d '{
      "model": "gemma3:1b",
      "prompt": "Write a short poem about AI",
      "stream": false
    }'
}

# Example 3: Chat with context
chat_example() {
  echo -e "\nChat example with gemma3:1b..."
  curl -s "${API_URL}/chat" \
    -H "Content-Type: application/json" \
    -d '{
      "model": "gemma3:1b",
      "messages": [
        {"role": "user", "content": "Hello, how are you today?"},
        {"role": "assistant", "content": "I am doing well, thank you for asking. How can I help you today?"},
        {"role": "user", "content": "Tell me about yourself."}
      ]
    }' | jq 2>/dev/null || curl -s "${API_URL}/chat" \
    -H "Content-Type: application/json" \
    -d '{
      "model": "gemma3:1b",
      "messages": [
        {"role": "user", "content": "Hello, how are you today?"},
        {"role": "assistant", "content": "I am doing well, thank you for asking. How can I help you today?"},
        {"role": "user", "content": "Tell me about yourself."}
      ]
    }'
}

# Example 4: Get model information
model_info() {
  echo -e "\nGetting model information..."
  curl -s "${API_URL}/show" \
    -H "Content-Type: application/json" \
    -d '{
      "name": "gemma3:1b"
    }' | jq 2>/dev/null || curl -s "${API_URL}/show" \
    -H "Content-Type: application/json" \
    -d '{
      "name": "gemma3:1b"
    }'
}

# Example 5: Streaming generation with proper handling
streaming_generation() {
  echo -e "\nStreaming generation example (will run for max 10 seconds)..."
  echo -e "Note: Each line is a separate JSON object. Press Ctrl+C to stop early.\n"
  
  # Using timeout to limit execution to 10 seconds in case streaming doesn't stop
  # The -N option ensures curl outputs each chunk as it arrives
  timeout 10 curl -N -s "${API_URL}/generate" \
    -H "Content-Type: application/json" \
    -d '{
      "model": "gemma3:1b",
      "prompt": "Write a recipe for chocolate chip cookies",
      "stream": true
    }'
  
  echo -e "\n\nStreaming complete or timeout reached."
}

# Main execution
if test_connection; then
  list_models
  generate_text
  chat_example
  model_info
  streaming_generation
else
  echo -e "\nWould you like to try a different server address? (y/n)"
  read -r response
  if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo "Enter the new server address (e.g., 192.168.1.100): "
    read -r new_ip
    echo "Do you want to use a different port? (default: 11434) (y/n)"
    read -r change_port
    if [[ "$change_port" =~ ^([yY][eE][sS]|[yY])$ ]]; then
      echo "Enter the port number: "
      read -r new_port
      sed -i.bak "s|http://192.168.1.166:11434/api|http://${new_ip}:${new_port}/api|g" "$0"
    else
      sed -i.bak "s|http://192.168.1.166:11434/api|http://${new_ip}:11434/api|g" "$0"
    fi
    echo "Script updated with new server address. Please run it again."
  fi
fi
