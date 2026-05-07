@echo off
chcp 65001 >nul 2>&1
title DMGHG 4K 画质解锁工具

:: ========================================
:: dmghg-4k-unlocker — 单文件自解压执行版
:: 放在任意位置运行，自动找到 dmghg 并解除4K限制
:: ========================================

setlocal enabledelimitedexpansion

:: ------ 查找 dmghg 安装目录 ------
set "DMGHG_DIR="

:: 1) 检查当前目录
if exist "%~dp0resources\app.asar" set "DMGHG_DIR=%~dp0"
if exist "%~dp0dmghg.exe" set "DMGHG_DIR=%~dp0"

:: 2) 检查父目录
if not defined DMGHG_DIR (
    for %%I in ("%~dp0..") do (
        if exist "%%~fI\resources\app.asar" set "DMGHG_DIR=%%~fI\"
        if exist "%%~fI\dmghg.exe" set "DMGHG_DIR=%%~fI\"
    )
)

:: 3) 通过 dmghg.exe 进程查找安装路径
if not defined DMGHG_DIR (
    for /f "tokens=2 delims==" %%I in ('wmic process where "name='dmghg.exe'" get ExecutablePath /value 2^>nul') do (
        if exist "%%~dpIresources\app.asar" set "DMGHG_DIR=%%~dpI"
    )
)

if not defined DMGHG_DIR (
    cls
    echo ========================================
    echo   未找到 dmghg 安装目录！
    echo.
    echo   请先将 dmghg 运行一次，或将本脚本放到
    echo   dmghg.exe 所在目录后重试。
    echo ========================================
    echo.
    pause
    exit /b 1
)

set "ASAR=%DMGHG_DIR%resources\app.asar"
if not exist "%ASAR%" (
    echo 错误: 找不到 %ASAR%
    pause
    exit /b 1
)

echo.
echo   ██████╗ ███╗   ███╗ ██████╗ ██╗  ██╗ ██████╗
echo   ██╔══██╗████╗ ████║██╔════╝ ██║  ██║██╔════╝
echo   ██║  ██║██╔████╔██║██║  ███╗███████║██║  ███╗
echo   ██║  ██║██║╚██╔╝██║██║   ██║██╔══██║██║   ██║
echo   ██████╔╝██║ ╚═╝ ██║╚██████╔╝██║  ██║╚██████╔╝
echo   ╚═════╝ ╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═╝ ╚═════╝
echo.
echo   DMGHG 4K 画质解锁工具 v1.0
echo   By Ainxin-1
echo ========================================
echo.
echo   检测到 dmghg: %DMGHG_DIR%
echo.

:: ------ 检测是否需要管理员权限 ------
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo ! 需要管理员权限才能修改 app.asar
    echo   请右键 → "以管理员身份运行"
    echo.
    pause
    exit /b 1
)

:: ------ 提取内置的 patch.ps1 ------
set "PS_SCRIPT=%TEMP%\dmghg-patch.ps1"

> "%PS_SCRIPT%" (
echo $asar = "%DMGHG_DIR:\=\\%resources\\app.asar"
echo $extractDir = "$env:TEMP\dmghg-patch-4k"
echo $indexJs = "$extractDir\out\main\index.js"
echo.
echo if ^(-not ^(Test-Path $asar^)^) { exit 0 }
echo.
echo $tempDir = "$env:TEMP\dmghg-patch-check"
echo if ^(Test-Path $tempDir^) { Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue }
echo New-Item -ItemType Directory -Path $tempDir -Force ^| Out-Null
echo npx asar extract $asar $tempDir 2^>$null
echo $checkFile = "$tempDir\out\main\index.js"
echo $alreadyPatched = ^(Select-String -Path $checkFile -Pattern "return true" -SimpleMatch -Quiet^)
echo Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
echo if ^($alreadyPatched^) { Write-Output "[跳过] 4K 限制已解除"; exit 0 }
echo.
echo Write-Output "[1/2] 正在解除 4K 限制..."
echo New-Item -ItemType Directory -Path $extractDir -Force ^| Out-Null
echo npx asar extract $asar $extractDir 2^>$null
echo $content = [System.IO.File]::ReadAllText($indexJs^)
echo $content = $content -replace 'const Users = \{\s*isVip:\s*\(cid\)\s*=>\s*\{[^}]*\}[^}]*\};', 'const Users = { isVip: (cid) => { return true; } };'
echo [System.IO.File]::WriteAllText($indexJs, $content^)
echo.
echo Write-Output "[2/2] 正在重新打包..."
echo Remove-Item -Force $asar -ErrorAction SilentlyContinue
echo npx asar pack $extractDir $asar 2^>$null
echo Remove-Item -Recurse -Force $extractDir -ErrorAction SilentlyContinue
echo Write-Output "完成!"
)

:: ------ 执行补丁 ------
echo [步骤 1/2] 正在解除 4K 画质 VIP 限制...
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%"
if %errorlevel% neq 0 (
    echo.
    echo ! 补丁执行失败，请确保已安装 Node.js
    pause
    exit /b 1
)

del "%PS_SCRIPT%" >nul 2>&1

echo.
echo ========================================
echo   ✓ 4K 画质限制已成功解除！
echo ========================================
echo.

:: ------ 安装自启动（可选） ------
echo 是否设置开机自动修补？（应对 dmghg 自动更新后限制恢复）
echo  [1] 是，安装自启动
echo  [2] 否，仅本次解锁
echo.
set "CHOICE=2"
set /p "CHOICE=请选择 (1/2，默认 2): "

if "%CHOICE%"=="1" (
    echo.
    echo 正在安装开机自启动...
    schtasks /Create /TN "DMGHG-4K-Unlocker" /TR "'%~f0'" /SC ONLOGON /DELAY 0000:30 /F >nul 2>&1
    if !errorlevel! equ 0 (
        echo ✓ 开机自启动已安装！
        echo   每次登录后 30 秒自动检测并修补。
    ) else (
        echo ! 自启动安装失败，请以管理员身份重试。
    )
)

echo.
echo ========================================
echo   操作完成！重启 dmghg 即可享受 4K 画质。
echo ========================================
echo.
pause
