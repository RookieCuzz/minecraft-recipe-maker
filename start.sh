#!/bin/bash

echo "正在启动 Minecraft Recipe Maker 开发服务器..."
echo ""

cd "$(dirname "$0")"

# 检查 node_modules 是否存在
if [ ! -d "node_modules" ]; then
    echo "未找到 node_modules，正在安装依赖..."
    npm install
    echo ""
fi

# 直接使用 npx 运行 vite
echo "启动服务器..."
nohup npx vite --host 0.0.0.0 > server.log 2>&1 &

PID=$!
echo $PID > server.pid

sleep 3

if ps -p $PID > /dev/null; then
    echo "服务器已在后台启动！"
    echo "进程 ID: $PID"
    echo "日志文件: server.log"
    echo "本地访问: http://localhost:5173/recipe2png/"
    echo "网络访问: http://$(hostname -I | awk '{print $1}'):5173/recipe2png/"
    echo ""
    echo "查看日志: tail -f server.log"
else
    echo "服务器启动失败，请查看 server.log"
    cat server.log
    exit 1
fi
