@echo off
chcp 65001 >nul
title DMGHG 4K 画质解锁工具
setlocal enabledelayedexpansion

:: 检测管理员权限
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo ! 请右键选择"以管理员身份运行"本脚本
    pause
    exit /b 1
)

:: 确定脚本所在目录为 dmghg 根目录
set "ROOT=%~dp0"
set "ASAR=%ROOT%resources\app.asar"

:: 如果当前目录没有 resources，尝试向上一级
if not exist "%ASAR%" (
    for %%I in ("%ROOT%..") do (
        if exist "%%~fI\resources\app.asar" set "ASAR=%%~fI\resources\app.asar"
    )
)

if not exist "%ASAR%" (
    echo ! 未找到 app.asar
    echo   请将本脚本放在 dmghg 安装目录（与 dmghg.exe 同目录）后重试。
    pause
    exit /b 1
)

echo   dmghg 4K 画质解锁工具
echo ========================================
echo.
echo [1/3] 正在解包 app.asar ...
set "EXTRACT=%TEMP%\dmghg-patch-4k"
if exist "%EXTRACT%" rmdir /s /q "%EXTRACT%" >nul 2>&1
md "%EXTRACT%" >nul 2>&1
call npx asar extract "%ASAR%" "%EXTRACT%" >nul 2>&1
if %errorlevel% neq 0 (
    echo ! 解包失败，请确保已安装 Node.js (https://nodejs.org)
    pause
    exit /b 1
)

:: 先检查是否已经解锁过
findstr /C:"return true" "%EXTRACT%\out\main\index.js" >nul 2>&1
if !errorlevel! equ 0 (
    echo [跳过] 4K 限制已解除，无需重复操作。
    echo.
    goto :REPACK
)

echo [2/3] 正在解除 4K 限制 ...
copy "%EXTRACT%\out\main\index.js" "%EXTRACT%\out\main\index.js.bak" >nul 2>&1
powershell -NoProfile -Command ^
    "$c = [System.IO.File]::ReadAllText('%EXTRACT:\=\\%\\out\\main\\index.js');" ^
    "$c = $c -replace 'const Users = \{\s*isVip:\s*\(cid\)\s*=>\s*\{[^}]*\}[^}]*\};', 'const Users = { isVip: (cid) => { return true; } };';" ^
    "[System.IO.File]::WriteAllText('%EXTRACT:\=\\%\\out\\main\\index.js', $c);"
echo      成功！

:REPACK
echo [3/3] 正在重新打包 app.asar ...
del /f /q "%ASAR%" >nul 2>&1
call npx asar pack "%EXTRACT%" "%ASAR%" >nul 2>&1
rmdir /s /q "%EXTRACT%" >nul 2>&1

echo.
echo ========================================
echo   ^✓ 完成！4K 画质限制已解除
echo.
echo   重启 dmghg 即可生效
echo ========================================
echo.
pause
