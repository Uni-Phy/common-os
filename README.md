# Common Compute OS

<p align="center">
  <img src="https://via.placeholder.com/150?text=CC+OS" alt="Common Compute Logo" width="150" height="150">
</p>

<p align="center">
  <strong>A minimalist operating system for developers building edge AI applications</strong>
</p>

<p align="center">
  <a href="#overview">Overview</a> •
  <a href="#key-features">Key Features</a> •
  <a href="#quick-start">Quick Start</a> •
  <a href="#directory-structure">Directory Structure</a> •
  <a href="#contributing">Contributing</a> •
  <a href="#license">License</a>
</p>

## Overview

Common Compute OS is a lightweight, developer-friendly operating system built on DietPi, designed to serve as a foundation for edge AI applications. It provides a minimalist base with Ollama pre-installed, allowing developers to quickly deploy and run large language models (LLMs) on Raspberry Pi and other compatible devices.

This project eliminates the complexity of setting up an AI-ready environment from scratch, focusing on performance optimization and ease of use. With Common Compute OS, developers can start building AI applications immediately without worrying about the underlying infrastructure.

## Key Features

- **Minimalist Design**: Only essential components included to maximize available resources
- **Pre-installed Ollama**: Run state-of-the-art LLMs locally without complex setup
- **Performance Optimized**: CPU governor, swap, and system settings configured for AI workloads
- **Developer Focused**: Easy-to-use API and management tools for integrating AI into applications
- **Resource Efficient**: Carefully tuned for optimal performance on resource-constrained devices
- **Secure By Default**: Minimal attack surface with only essential services exposed
- **Highly Customizable**: Easily extensible for specific application requirements

## Quick Start

### Prerequisites

- Raspberry Pi 4 (4GB or 8GB RAM recommended) or compatible device
- 16GB+ microSD card
- Power supply
- Internet connection for initial setup

### Installation

#### Method 1: Starting with DietPi

1. Download the base DietPi OS image for your device from the [official DietPi website](https://dietpi.com/downloads/)
2. Flash the image to your microSD card using tools like [Etcher](https://www.balena.io/etcher/) or dd
3. Re-mount the SD card on your computer and copy the Common Compute OS configuration files:
   ```bash
   # From the root of this repository
   cp -r config/* /path/to/sd/card/
   ```
4. Configure WiFi and other settings using our USB setup script:
   ```bash
   cd cmd
   ./setup_usb.sh
   ```
5. Safely eject the microSD card and insert it into your Raspberry Pi
6. Power on your device and wait for the automatic setup process to complete (5-15 minutes)
7. Find your device's IP address via your router or using `hostname -I` if you have a display connected

#### Method 2: Using a Pre-configured Image

A pre-configured image will be available in future releases. For now, please use Method 1.

### Using Ollama

Once setup is complete, you can access the Ollama API at:

```
http://[your-device-IP]:11434
```

Example API usage:

```bash
# Generate text with the default model
curl http://[your-device-IP]:11434/api/generate -d '{
  "model": "gemma3:1b",
  "prompt": "Hello, how are you?"
}'

# List available models
curl http://[your-device-IP]:11434/api/tags
```

For more detailed instructions and examples, see the [Ollama documentation](docs/README_OLLAMA_API.md).

## Directory Structure

The project is organized with the following directory structure:

```
common-compute-os/
├── cmd/                    # Command-line tools and scripts
│   └── update_usb_config.sh            # USB device management
│
├── config/                 # Configuration files
│   ├── Automation_Custom_Script.sh     # Main setup script
│   ├── dietpi.txt                      # DietPi system configuration
│   └── dietpi-wifi.txt                 # WiFi connection settings
│
├── docs/                   # Documentation
│   ├── README_SETUP.md                 # Setup guide
│   ├── README_OLLAMA_API.md            # API documentation
│   ├── configure_ollama_server.md      # Server configuration guide
│   └── ollama_check.md                 # Troubleshooting guide
│
├── test/                   # Testing scripts
│   ├── improved_ollama_api_test.sh          # Enhanced API interactions
│   ├── ollama_api_examples.sh          # Example API usage
│   └── ollama_connection_tester.sh     # Network connectivity tests
│
└── README.md               # This file
```

## Advanced Usage

### Managing Models

Common Compute OS includes a helper script for managing Ollama models:

```bash
# List all installed models
ollama-manage list

# Download a new model
ollama-manage pull llama3.2:1b

# Remove a model
ollama-manage remove neural-chat

# Check storage usage
ollama-manage space
```

### Customizing the Setup

To customize the installation process, modify the files in the `config/` directory before flashing the image to your microSD card. See [Setup Guide](docs/README_SETUP.md) for details on customization options.

#### USB Drive Configuration Tool

Common Compute OS includes a USB drive configuration tool that simplifies the process of setting up WiFi credentials and copying configuration files to a USB drive:

```bash
cd cmd
./setup_usb.sh
```

This interactive script:

- Detects and lists available USB drives on your system
- Allows you to select which drive to configure
- Prompts for WiFi credentials (SSID and password)
- Updates the dietpi-wifi.txt file with your WiFi settings
- Copies all configuration files from the config directory to the USB drive

The script provides color-coded prompts and detailed error messages to guide you through the process. Once complete, insert the USB drive into your Common Compute OS device during first boot to automatically apply your custom configurations.

## Frequently Asked Questions

**Q: What models can I run on a Raspberry Pi?**

A: For the best experience, we recommend:
- 8GB Raspberry Pi: Models up to 7B parameters (~4GB)
- 4GB Raspberry Pi: Models under 3B parameters (~2GB)
- Recommended starter model: gemma3:1b (815MB)

**Q: How do I integrate Ollama with my application?**

A: You can access Ollama via its REST API. Examples for various programming languages are available in the [API documentation](docs/README_OLLAMA_API.md).

**Q: Can I run this on hardware other than Raspberry Pi?**

A: Yes, Common Compute OS should work on any ARM64 device supported by DietPi, though official testing is done on Raspberry Pi hardware.

## Support the Project

If you find Common Compute OS valuable for your projects, please consider supporting its development through cryptocurrency donations. Your contributions help us maintain and improve this project.

<div align="center">
  <div style="display:flex; justify-content: center; gap: 40px;">
    <div>
      <h3>Bitcoin - Mainnet</h3>
      <img src="docs/bitcoin.png" alt="Bitcoin QR Code" width="150" height="150">
      <p><code>bc1qg8mkfye5fry92j2rql73t00ye8354vkalujshk</code></p>
    </div>
    <div>
      <h3>Ethereum-Mainnet</h3>
      <img src="docs/ethereum.png" alt="Ethereum QR Code" width="150" height="150">
      <p><code>0xa6aE69AbEc6394d591bdF5B81Caf7aF440363a37</code></p>
    </div>
  </div>
</div>

## Contributing

Contributions are welcome! If you'd like to help improve Common Compute OS:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

Please ensure your code follows our style guidelines and include appropriate tests.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [DietPi](https://dietpi.com/) for the base OS
- [Ollama](https://ollama.ai/) for the local LLM runtime
- All contributors and community members

---

<p align="center">
  Made with ❤️ by the Common Compute Team
</p>

