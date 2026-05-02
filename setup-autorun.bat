@echo off
chcp 65001 >nul
title DMGHG 4K 自动修补 - 安装
setlocal enabledelayedexpansion

:: 检测管理员权限
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo ! 请右键选择"以管理员身份运行"本脚本
    pause
    exit /b 1
)

set "ROOT=%~dp0"
set "SCRIPT=%ROOT%patch-4k.bat"

if not exist "%SCRIPT%" (
    echo ! 未找到 patch-4k.bat，请将本文件与 patch-4k.bat 放在同一目录。
    pause
    exit /b 1
)

:: 用计划任务代替开机启动（更可靠、无窗口）
schtasks /Create /TN "DMGHG-4K-Patch" /TR "'%SCRIPT%'" /SC ONLOGON /DELAY 0000:30 /F >nul 2>&1

if %errorlevel% equ 0 (
    echo ========================================
    echo   ^✓ 自动修补已安装！
    echo.
    echo   每次开机登录 30 秒后自动检测并修补。
    echo   如果 dmghg 自动更新导致限制恢复，
    echo   重启电脑或重新登录即自动解除。
    echo ========================================
) else (
    echo.
    echo ! 安装失败，可能是权限不足。
    echo   请尝试以管理员身份运行。
)

echo.
pause
