#!/bin/bash

# Base URL
API_URL="http://192.168.1.166:11434/api"

# Example 1: List models
echo "Listing available models..."
curl -s "$API_URL/tags"

# Example 2: Generate text with the gemma3:1b model
echo -e "\n\nGenerating text with gemma3:1b..."
curl -s "$API_URL/generate" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gemma3:1b",
    "prompt": "Write a short poem about AI",
    "stream": false
  }'

# Example 3: Chat with the model (maintaining context)
echo -e "\n\nChat example with gemma3:1b..."
curl -s "$API_URL/chat" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gemma3:1b",
    "messages": [
      {"role": "user", "content": "Hello, how are you today?"},
      {"role": "assistant", "content": "I am doing well, thank you for asking. How can I help you today?"},
      {"role": "user", "content": "Tell me about yourself."}
    ]
  }'

# Example 4: Get model information
echo -e "\n\nGetting model information..."
curl -s "$API_URL/show" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "gemma3:1b"
  }'

# Example 5: Streaming generation
echo -e "\n\nStreaming generation example (press Ctrl+C to stop)..."
curl -s "$API_URL/generate" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gemma3:1b",
    "prompt": "Write a recipe for chocolate chip cookies",
    "stream": true
  }'

# Note: For more examples and parameters, see the official Ollama API documentation:
# https://github.com/ollama/ollama/blob/main/docs/api.md
