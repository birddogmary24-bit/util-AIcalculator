#!/bin/bash
# Load API key from .env
source "$(dirname "$0")/.env"

# 빌드 여부 선택 (--serve-only 플래그로 빌드 스킵)
if [ "$1" != "--serve-only" ]; then
  echo "Building web..."
  flutter build web \
    --dart-define=GEMINI_API_KEY=$GEMINI_API_KEY \
    --dart-define=PROXY_BASE_URL=$PROXY_BASE_URL \
    --dart-define=PROXY_APP_TOKEN=$PROXY_APP_TOKEN
  echo "Build complete."
fi

# Kill existing server on port 8200
lsof -ti:8200 | xargs kill -9 2>/dev/null

# Serve as background process (터미널 닫혀도 유지)
nohup python3 -m http.server 8200 --directory build/web \
  > /tmp/aicalc_server.log 2>&1 &

echo ""
echo "Server running at http://localhost:8200"
echo "  PID: $!  |  Logs: tail -f /tmp/aicalc_server.log"
echo "  Stop: lsof -ti:8200 | xargs kill -9"
