@echo off
chcp 65001 >nul
echo 正在启动 Minecraft Recipe Maker 开发服务器...
echo.

cd /d "%~dp0"

start /B node "C:\Program Files\nodejs\node_modules\npm\bin\npm-cli.js" run dev > server.log 2>&1

timeout /t 3 /nobreak >nul

echo 服务器已在后台启动！
echo 日志文件：server.log
echo 访问地址：http://localhost:5173/recipe2png/
echo.
echo 按任意键退出...
pause >nul
