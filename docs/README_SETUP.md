# Simplified Ollama Setup Guide

This document explains the automated setup process for Ollama on your Raspberry Pi device. After flashing your SD card with the DietPi image containing these files, the system will automatically configure itself as a functional local AI inference server.

## What is Ollama?

Ollama is an open-source platform that allows you to run large language models (LLMs) locally on your own hardware. This setup combines DietPi (a lightweight Debian-based OS) with Ollama to provide an affordable and secure way to run AI inference models on your Raspberry Pi.

## What Does the Automation Script Do?

The `config/Automation_Custom_Script.sh` automatically performs the following tasks during the first boot:

1. **System Update & Preparation**
   - Updates and upgrades the operating system

2. **Performance Optimization**
   - Configures CPU governor to "performance" mode for better inference speed
   - Increases swap space to 2GB to handle memory-intensive models
   - Sets up system logging for troubleshooting

3. **Ollama Installation & Configuration**
   - Installs the Ollama software
   - Configures Ollama to accept connections from any device on your network
   - Creates and enables a systemd service for automatic startup

4. **Model Setup**
   - Downloads the gemma3:1b model (~815MB), which is optimized for Raspberry Pi
   - Sets up the system for easy management of additional models

5. **Network & Security Setup**
   - Configures firewall rules (if UFW is installed)
   - Opens only the necessary ports (SSH and 11434 for Ollama API)

6. **Utility Scripts**
   - Creates the `ollama-manage` helper script for easy model management

## Accessing Your Ollama Server

After the setup completes (which may take 5-15 minutes depending on your internet speed), you can access:

- **Ollama API**: `http://[your-device-IP]:11434`

You can find your device's IP address using `hostname -I` on the Raspberry Pi or by checking your router's connected devices.

## Using the Ollama API

You can interact with Ollama directly through its API using curl commands:

```bash
# Generate text with the default model
curl http://[your-device-IP]:11434/api/generate -d '{
  "model": "gemma3:1b",
  "prompt": "Hello, how are you?"
}'

# List available models
curl http://[your-device-IP]:11434/api/tags

# Get model information
curl http://[your-device-IP]:11434/api/show -d '{"name": "gemma3:1b"}'
```

For more API commands, see the [Ollama API documentation](https://github.com/ollama/ollama/blob/main/docs/api.md).

## Lightweight Models for Raspberry Pi

The Raspberry Pi 8GB can run several lightweight LLM models effectively. Here are recommended models with their sizes:

| Model | Size | Description | Command to Install |
|-------|------|-------------|-------------------|
| gemma3:1b | 815MB | Fast, compact Google model for general tasks | *Installed by default* |
| llama3.2:1b | 1.3GB | Capable Meta model, good balance of size/quality | `ollama-manage pull llama3.2:1b` |
| phi4-mini | 2.5GB | Microsoft's smaller Phi-4 variant | `ollama-manage pull phi4-mini` |
| moondream | 829MB | Vision-capable small model | `ollama-manage pull moondream` |
| neural-chat | 4.1GB | Good conversational model | `ollama-manage pull neural-chat` |

**Memory Requirements:**
- For 8GB Raspberry Pi: Models up to 7B parameters (~4GB) should work well
- For 4GB Raspberry Pi: Stick to models under 3B parameters (~2GB)

## Managing Models

The setup includes a helper script called `ollama-manage` for easy model management:

```bash
# List all installed models
ollama-manage list

# Download a new model
ollama-manage pull [model_name]
Example: ollama-manage pull llama3.2:1b

# Remove a model
ollama-manage remove [model_name]
Example: ollama-manage remove neural-chat

# Check storage usage
ollama-manage space
```

Models are stored in the `~/.ollama` directory by default.

## Modifying the Setup Script

If you need to customize the setup script before flashing your SD card, here are some common modifications:

### Installing Different Default Models

Edit line 114 in `config/Automation_Custom_Script.sh`:

```bash
# Original
ollama pull gemma3:1b

# To change to a different model or add multiple models
ollama pull llama3.2:1b
ollama pull phi4-mini
```

### Adjusting Swap Size

Edit line 81 in `config/Automation_Custom_Script.sh` to change the swap size:

```bash
# Original (2GB swap)
fallocate -l 2G /var/swap

# Change to a different size (e.g., 4GB)
fallocate -l 4G /var/swap
```

## Troubleshooting Common Issues

### Ollama Service Not Running

1. **Check Ollama service status**:
   ```bash
   systemctl status ollama
   ```

2. **Verify network connectivity**:
   ```bash
   curl -v http://localhost:11434/api/tags
   ```

3. **Restart the service**:
   ```bash
   systemctl restart ollama
   ```

### Models Failing to Download

1. **Check internet connectivity**:
   ```bash
   ping -c 3 ollama.ai
   ```

2. **Check disk space**:
   ```bash
   df -h
   ```

3. **Try downloading with verbose output**:
   ```bash
   OLLAMA_HOST=0.0.0.0:11434 ollama pull gemma3:1b
   ```

### Performance Issues

1. **Monitor system resources**:
   ```bash
   htop
   ```

2. **Check system temperature**:
   ```bash
   vcgencmd measure_temp
   ```

3. **Analyze Ollama logs**:
   ```bash
   journalctl -u ollama
   ```

4. **Try a smaller model** if performance is sluggish

### Log Locations

- Setup log: `/var/log/ollama-setup.log`
- Ollama service logs: `journalctl -u ollama`

## Advanced Configuration

### Setting Up a Client

Since this is an API-only setup, you might want to use one of these options to interact with your Ollama server:

1. **Command Line**: Use curl commands as shown above
2. **Python Client**: Use the [Ollama Python client](https://github.com/ollama/ollama-python)
3. **Install a UI Later**: If needed, you can add a UI like Open WebUI by following the instructions on their GitHub repo

### Enabling HTTPS

For secure access, consider setting up Nginx as a reverse proxy with Let's Encrypt SSL certificates.

## Getting Help

If you encounter issues not covered in this guide, check the following resources:
- Ollama documentation: https://github.com/ollama/ollama/blob/main/README.md
- Ollama API reference: https://github.com/ollama/ollama/blob/main/docs/api.md
- DietPi forums: https://dietpi.com/forum/

