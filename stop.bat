@echo off
chcp 65001 >nul
echo 正在停止 Minecraft Recipe Maker 开发服务器...
echo.

taskkill /F /IM node.exe /FI "WINDOWTITLE eq *vite*" 2>nul

if %errorlevel% equ 0 (
    echo 服务器已停止！
) else (
    echo 未找到运行中的服务器进程
)

echo.
echo 按任意键退出...
pause >nul
