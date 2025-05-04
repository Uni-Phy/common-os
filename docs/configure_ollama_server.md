# Configuring Ollama to Accept External Connections

To ensure Ollama listens on all network interfaces (not just localhost), you need to configure it properly on the server machine (192.168.1.166). Here's a step-by-step guide:

## 1. SSH into your Ollama server

```bash
ssh user@192.168.1.166
```

Replace `user` with your username on that machine.

## 2. Check current Ollama service status

```bash
systemctl status ollama    # If installed as a service
# OR
ps aux | grep ollama       # To check if it's running
```

## 3. Configure Ollama to listen on all interfaces

Ollama can be configured via environment variables. You need to set the `OLLAMA_HOST` variable:

### If running as a service:

Create or edit the systemd service file:

```bash
sudo mkdir -p /etc/systemd/system/ollama.service.d
sudo nano /etc/systemd/system/ollama.service.d/override.conf
```

Add these lines:

```
[Service]
Environment="OLLAMA_HOST=0.0.0.0:11434"
```

Save and reload the daemon:

```bash
sudo systemctl daemon-reload
sudo systemctl restart ollama
```

### If running manually:

Run Ollama with the environment variable:

```bash
OLLAMA_HOST=0.0.0.0:11434 ollama serve
```

### Using a configuration file:

Create a `.env` file in the Ollama directory:

```bash
echo "OLLAMA_HOST=0.0.0.0:11434" > ~/.ollama/.env
```

Then restart Ollama.

## 4. Check firewall settings

Ensure port 11434 is open in your firewall:

```bash
# For UFW (Ubuntu/Debian)
sudo ufw allow 11434/tcp

# For firewalld (Fedora/RHEL/CentOS)
sudo firewall-cmd --permanent --add-port=11434/tcp
sudo firewall-cmd --reload
```

## 5. Verify Ollama is listening on all interfaces

After restarting Ollama, check if it's listening on all interfaces:

```bash
sudo netstat -tulpn | grep 11434
# OR
sudo ss -tulpn | grep 11434
```

You should see something like:
```
tcp   0   0 0.0.0.0:11434    0.0.0.0:*    LISTEN   12345/ollama
```

The `0.0.0.0:11434` means it's listening on all interfaces.

## 6. Test connectivity from your client machine

Now you can run the connection tester from your client machine:

```bash
./test/ollama_connection_tester.sh
```

## Security Considerations

When exposing Ollama to the network:

1. **Access Control**: Consider implementing an authentication mechanism or reverse proxy
2. **Network Isolation**: Use a firewall to restrict access only to trusted IP addresses
3. **TLS/SSL**: For production use, consider setting up HTTPS with a reverse proxy like Nginx

## Additional Options

For more advanced configurations, you can set:

- `OLLAMA_ORIGINS`: Allowed CORS origins (comma-separated)
- `OLLAMA_MODELS`: Custom path for storing models
- `OLLAMA_HOST_TIMEOUT`: Connection timeout in seconds
