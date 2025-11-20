#!/bin/bash

echo "正在停止 Minecraft Recipe Maker 开发服务器..."
echo ""

cd "$(dirname "$0")"

if [ -f server.pid ]; then
    PID=$(cat server.pid)
    
    if ps -p $PID > /dev/null; then
        kill $PID
        echo "服务器已停止 (PID: $PID)"
        rm server.pid
    else
        echo "进程不存在 (PID: $PID)"
        rm server.pid
    fi
else
    echo "未找到 server.pid 文件"
    echo "尝试查找并停止所有 vite 进程..."
    
    pkill -f "vite"
    
    if [ $? -eq 0 ]; then
        echo "已停止 vite 进程"
    else
        echo "未找到运行中的服务器进程"
    fi
fi
