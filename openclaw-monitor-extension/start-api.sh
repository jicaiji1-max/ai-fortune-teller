#!/bin/bash
# OpenClaw Monitor Extension - API Server Startup Script

# 自动检测脚本所在目录（无论用户把仓库放在哪里都能工作）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/tmp/openclaw-monitor-api.log"
PID_FILE="/tmp/openclaw-monitor-api.pid"

# 检查是否已经在运行
if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if ps -p $PID > /dev/null 2>&1; then
        echo "✅ API server is already running (PID: $PID)"
        exit 0
    else
        echo "⚠️  Removing stale PID file..."
        rm -f "$PID_FILE"
    fi
fi

# 检查 openclaw-sessions-api.js 是否存在
if [ ! -f "$SCRIPT_DIR/openclaw-sessions-api.js" ]; then
    echo "❌ Error: openclaw-sessions-api.js not found in $SCRIPT_DIR"
    echo "Please make sure you're running this script from the openclaw-monitor-extension directory."
    exit 1
fi

# 启动 API 服务
echo "🚀 Starting OpenClaw Monitor API..."
echo "📂 Working directory: $SCRIPT_DIR"
cd "$SCRIPT_DIR"
nohup node openclaw-sessions-api.js > "$LOG_FILE" 2>&1 &
echo $! > "$PID_FILE"

echo "✅ API server started (PID: $(cat $PID_FILE))"
echo "📝 Log file: $LOG_FILE"
echo ""
echo "To check logs: tail -f $LOG_FILE"
echo "To stop server: kill $(cat $PID_FILE)"
