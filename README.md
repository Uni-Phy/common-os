# Common Compute OS — Ollama Lite

Run a local LLM on your Raspberry Pi with a web chat UI. One script does everything.

**What you get:**
- [Ollama](https://ollama.ai/) serving models on port `11434`
- [nextjs-ollama-llm-ui](https://github.com/jakobhoeg/nextjs-ollama-llm-ui) chat interface on port `3000`
- Both running as systemd services, auto-starting on boot

## Prerequisites

- Raspberry Pi 4/5 (4GB+ RAM recommended) running **Raspberry Pi OS** (64-bit)
- 16GB+ microSD card
- Internet connection
- SSH access to your Pi

## Install

SSH into your Pi, then:

```bash
git clone https://github.com/UniPhy/common-os.git
cd common-os
git checkout ollama-lite
sudo ./install.sh
```

The installer will:
1. Install Node.js, Ollama, and dependencies
2. Configure Ollama to accept network connections
3. Download the `gemma3:1b` model (~815MB)
4. Clone, build, and start the web UI

Total install time: ~10-20 minutes on RPi 4 (depends on internet speed).

## Access

After install, open in your browser:

- **Chat UI:** `http://<your-pi-ip>:3000`
- **Ollama API:** `http://<your-pi-ip>:11434`

Find your Pi's IP with `hostname -I` on the Pi.

## Manage

```bash
# Service status
sudo systemctl status ollama
sudo systemctl status coco-web-ui

# View logs
journalctl -u ollama -f
journalctl -u coco-web-ui -f

# Restart services
sudo systemctl restart ollama
sudo systemctl restart coco-web-ui

# Manage models
ollama list
ollama pull llama3.2:1b
ollama rm <model-name>
```

## Recommended Models for RPi

| RAM | Max Parameters | Suggested Models |
|-----|---------------|------------------|
| 4GB | ~3B | `gemma3:1b` |
| 8GB | ~7B | `gemma3:1b`, `llama3.2:3b`, `phi3:mini` |

## Uninstall

```bash
sudo ./scripts/uninstall.sh
```

## Project Structure

```
common-os/
├── install.sh                # Single-command installer
├── config/
│   ├── ollama-override.conf  # Ollama network config
│   └── coco-web-ui.service   # Web UI systemd service
├── scripts/
│   └── uninstall.sh          # Clean removal
├── LICENSE
└── README.md
```

## Troubleshooting

**Ollama won't start:**
```bash
journalctl -u ollama --no-pager -n 50
```

**Web UI won't start:**
```bash
journalctl -u coco-web-ui --no-pager -n 50
```

**Can't connect from another device:**
Make sure your Pi and device are on the same network. Test with:
```bash
curl http://<pi-ip>:11434/api/tags
```

**Out of memory:**
Try a smaller model. On 4GB Pi, stick to `gemma3:1b`.

## License

MIT — see [LICENSE](LICENSE).

---

<p align="center">made ▲ underground ▼ by coco</p>

