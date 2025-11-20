#!/bin/bash

echo "正在启动 Minecraft Recipe Maker 开发服务器..."
echo ""

cd "$(dirname "$0")"

nohup npm run dev > server.log 2>&1 &

PID=$!
echo $PID > server.pid

sleep 2

if ps -p $PID > /dev/null; then
    echo "服务器已在后台启动！"
    echo "进程 ID: $PID"
    echo "日志文件: server.log"
    echo "访问地址: http://localhost:5173/recipe2png/"
else
    echo "服务器启动失败，请查看 server.log"
    exit 1
fi
