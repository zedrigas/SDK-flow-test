#!/bin/zsh
# Double-click to serve the SDK Flow Feel prototype on your local network.
cd "$(dirname "$0")"
IP=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null)
HOST=$(scutil --get LocalHostName 2>/dev/null)
echo ""
echo "  SDK Flow Feel — local server"
echo "  On your iPhone (same Wi-Fi) open:"
echo "    http://${IP:-<mac-ip>}:8080"
[ -n "$HOST" ] && echo "    or http://${HOST}.local:8080"
echo ""
echo "  Press Ctrl+C to stop."
python3 -m http.server 8080 --bind 0.0.0.0
