---
name: Bug Report
about: Create a report to help us improve Common Compute OS
title: '[BUG] '
labels: 'bug'
assignees: ''

---

## Bug Description
A clear and concise description of what the bug is.

## Steps to Reproduce
1. Go to '...'
2. Click on '....'
3. Scroll down to '....'
4. See error

## Expected Behavior
A clear and concise description of what you expected to happen.

## Actual Behavior
A clear and concise description of what actually happened.

## Screenshots
If applicable, add screenshots to help explain your problem.

## Hardware Information
- **Device**: [e.g. Raspberry Pi 4 8GB]
- **SD Card**: [e.g. 32GB SanDisk Ultra]
- **Power Supply**: [e.g. Official Raspberry Pi Power Supply]

## Software Environment
- **Common Compute OS Version**: [e.g. latest, commit hash, or date installed]
- **Ollama Version**: [e.g. output of `ollama --version`]
- **Models Installed**: [e.g. gemma3:1b, llama3.2:1b]

## Logs
Please include relevant log files:
```
# System logs
sudo journalctl -u ollama -n 50

# Common Compute setup logs
cat /var/log/ollama-setup.log

# Any other relevant logs
```

## Network Information
- **Connection Type**: [e.g. WiFi, Ethernet]
- **Router**: [e.g. brand/model if relevant]
- **Network Speed**: [e.g. if performance related]

## Additional Context
Add any other context about the problem here.

## Possible Solution
If you have ideas about what might be causing this issue or how to fix it, please share.
