# Ollama API Guide for 192.168.1.166

This guide explains how to interact with the Ollama API running on your server at 192.168.1.166 using curl commands.

## Using the Script

I've created a script with several example curl commands that you can use to interact with the Ollama API:

1. Make the script executable:
   ```
   chmod +x test/ollama_api_examples.sh
   ```

2. Run the script:
   ```
   ./test/ollama_api_examples.sh
   ```

3. You can also run individual commands from the script for testing.

## API Endpoints Explained

1. **List Models** - `/api/tags`
   - Returns a list of all models available on your Ollama server.

2. **Generate Text** - `/api/generate`
   - Generates text based on a prompt using a specified model.
   - Parameters:
     - `model`: The model to use (e.g., "gemma3:1b")
     - `prompt`: The input text
     - `stream`: Set to true for streaming output, false for complete response

3. **Chat Completion** - `/api/chat`
   - Maintains conversation context between messages.
   - Requires an array of messages with roles ("user" or "assistant").

4. **Model Information** - `/api/show`
   - Returns information about a specific model.

5. **Embedding Generation** - `/api/embeddings`
   - Generates vector embeddings for input text (not included in examples).

## Common Parameters

- **temperature**: Controls randomness (0.0 to 2.0, default 0.8)
- **top_p**: Controls diversity (0.0 to 1.0, default 0.9)
- **top_k**: Limits vocabulary to top k options (default 40)
- **max_tokens**: Maximum number of tokens to generate

## Additional Notes

- The Ollama API server runs on port 11434 by default.
- For streaming responses, you may want to pipe the output through a JSON processor like jq.
- These examples specifically target your model "gemma3:1b".

For more detailed documentation, visit:
https://github.com/ollama/ollama/blob/main/docs/api.md
