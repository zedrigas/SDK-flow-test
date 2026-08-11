#!/bin/zsh
# Double-click to serve the SDK Flow Feel prototype on your local network.
# Sends Cache-Control: no-store so phones always load the newest build.
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
python3 - <<'PY'
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer

class NoStoreHandler(SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Cache-Control', 'no-store, must-revalidate')
        self.send_header('Pragma', 'no-cache')
        self.send_header('Expires', '0')
        super().end_headers()

ThreadingHTTPServer(('0.0.0.0', 8080), NoStoreHandler).serve_forever()
PY
