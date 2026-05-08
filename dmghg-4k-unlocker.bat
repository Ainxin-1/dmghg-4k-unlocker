@echo off
chcp 65001 >nul 2>&1
title DMGHG 4K 解锁助手 v3.0

:: ========================================
:: dmghg-4k-unlocker v3.0
:: 纯 PowerShell 实现，无需 Node.js
:: 放在 dmghg.exe 同级目录，运行一次即可
:: ========================================

setlocal enabledelayedexpansion

:: ------ 查找 dmghg 安装目录 ------
set "DMGHG_DIR="

if exist "%~dp0resources\app.asar" set "DMGHG_DIR=%~dp0"
if exist "%~dp0dmghg.exe" set "DMGHG_DIR=%~dp0"

if not defined DMGHG_DIR (
    for %%I in ("%~dp0..") do (
        if exist "%%~fI\resources\app.asar" set "DMGHG_DIR=%%~fI\"
        if exist "%%~fI\dmghg.exe" set "DMGHG_DIR=%%~fI\"
    )
)

if not defined DMGHG_DIR (
    for /f "tokens=2 delims==" %%I in ('wmic process where "name='dmghg.exe'" get ExecutablePath /value 2^>nul') do (
        if exist "%%~dpIresources\app.asar" set "DMGHG_DIR=%%~dpI"
    )
)

if not defined DMGHG_DIR (
    cls
    echo ========================================
    echo   未找到 dmghg 安装目录！
    echo   请将本脚本放到 dmghg.exe 所在目录后重试
    echo ========================================
    pause
    exit /b 1
)

set "ASAR=%DMGHG_DIR%resources\app.asar"
if not exist "%ASAR%" (
    echo 错误: 找不到 %ASAR%
    pause
    exit /b 1
)

:: ------ 解析参数 ------
set "ACTION=run"
if /i "%1"=="--restore" set "ACTION=restore"
if /i "%1"=="--startup" set "ACTION=startup"

:: ------ 开机自检模式（静默执行后退出）------
if "%ACTION%"=="startup" (
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$lines=Get-Content '%~f0' -Encoding UTF8;" ^
    "$s=[array]::IndexOf($lines,'#===PS1_START===');" ^
    "$e=[array]::IndexOf($lines,'#===PS1_END===');" ^
    "$script=($lines[($s+1)..($e-1)] -join [Environment]::NewLine).Replace('@@DMGHG_DIR@@','%DMGHG_DIR:\=\\%').Replace('@@BATCH_ACTION@@','startup');" ^
    "iex $script" >nul 2>&1
    exit /b 0
)

:: ------ 检测/自动提权管理员 ------
net session >nul 2>&1
if %errorlevel% neq 0 (
    powershell -NoProfile -Command "Start-Process cmd -ArgumentList '/c \"\"%~s0\"\" %*' -Verb RunAs"
    exit /b 0
)

echo.
echo   DMGHG 4K 解锁助手 v3.0
echo   检测到 dmghg: %DMGHG_DIR%
echo.

:: ------ 提取并执行内嵌 PowerShell 补丁脚本 ------
echo   正在检查补丁状态...
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
"$lines=Get-Content '%~f0' -Encoding UTF8;" ^
"$s=[array]::IndexOf($lines,'#===PS1_START===');" ^
"$e=[array]::IndexOf($lines,'#===PS1_END===');" ^
"$script=($lines[($s+1)..($e-1)] -join [Environment]::NewLine).Replace('@@DMGHG_DIR@@','%DMGHG_DIR:\=\\%').Replace('@@BATCH_ACTION@@','%ACTION%');" ^
"iex $script"

if %errorlevel% neq 0 (
    echo.
    pause
    exit /b 1
)

:: ------ 恢复模式：清理快捷方式和计划任务 ------
if "%ACTION%"=="restore" (
    echo.
    echo   正在清理开机自检...
    schtasks /delete /tn "DMGHG-4K-Unlocker" /f >nul 2>&1
    echo   正在恢复桌面快捷方式...
    powershell -NoProfile -Command ^
    "$ws=New-Object -ComObject WScript.Shell;" ^
    "$targetExe='%DMGHG_DIR:\=\\%dmghg.exe';" ^
    "$desktop=[Environment]::GetFolderPath('Desktop');" ^
    "$pubDesktop=[Environment]::GetFolderPath('CommonDesktopDirectory');" ^
    "foreach($dir in @($desktop,$pubDesktop)){;" ^
    "  Get-ChildItem \"$dir\*.lnk\" -EA 0 | Where-Object { $_.Name -match '动漫共和国|dmghg|DMGHG' } | ForEach-Object {;" ^
    "    $lnk=$ws.CreateShortcut($_.FullName);" ^
    "    $lnk.TargetPath=$targetExe;" ^
    "    $lnk.WorkingDirectory='%DMGHG_DIR:\=\\%';" ^
    "    $lnk.Save();" ^
    "  };" ^
    "}"
    echo ========================================
    echo   已完全恢复原始状态！
    echo ========================================
    pause
    exit /b 0
)

:: ------ 设置桌面快捷方式（指向本脚本）------
echo   正在设置桌面快捷方式...
powershell -NoProfile -Command ^
"$ws=New-Object -ComObject WScript.Shell;" ^
"$scriptPath='%DMGHG_DIR:\=\\%%~nxs0';" ^
"$targetExe='%DMGHG_DIR:\=\\%dmghg.exe';" ^
"$desktop=[Environment]::GetFolderPath('Desktop');" ^
"$pubDesktop=[Environment]::GetFolderPath('CommonDesktopDirectory');" ^
"$found=$false;" ^
"foreach($dir in @($desktop,$pubDesktop)){;" ^
"  Get-ChildItem \"$dir\*.lnk\" -EA 0 | Where-Object { $_.Name -match '动漫共和国|dmghg|DMGHG' } | ForEach-Object {;" ^
"    $lnk=$ws.CreateShortcut($_.FullName);" ^
"    $lnk.TargetPath=$scriptPath;" ^
"    $lnk.WorkingDirectory='%DMGHG_DIR:\=\\%';" ^
"    $lnk.IconLocation=\"$targetExe, 0\";" ^
"    $lnk.Save();" ^
"    Write-Output \"  -> 已修改: $($_.Name)\";" ^
"    $found=$true;" ^
"  };" ^
"};" ^
"if (-not $found) {;" ^
"  $lnk=$ws.CreateShortcut(\"$desktop\动漫共和国.lnk\");" ^
"  $lnk.TargetPath=$scriptPath;" ^
"  $lnk.WorkingDirectory='%DMGHG_DIR:\=\\%';" ^
"  $lnk.IconLocation=\"$targetExe, 0\";" ^
"  $lnk.Save();" ^
"  Write-Output '  -> 已创建: 桌面快捷方式';" ^
"}"

:: ------ 设置开机自检（计划任务）------
echo   正在设置开机自检...
schtasks /create /tn "DMGHG-4K-Unlocker" /tr "'%~s0' --startup" /sc onlogon /rl highest /f >nul 2>&1
if %errorlevel% equ 0 (
    echo   -> 开机自检已启用
) else (
    echo   -> 开机自检设置失败（不影响使用）
)

echo.
echo ========================================
echo   准备就绪，正在启动动漫共和国...
echo ========================================

start "" "%DMGHG_DIR%dmghg.exe"
exit /b 0


:: ============================================================
:: 内嵌 PowerShell 脚本（@@DMGHG_DIR@@ 占位符会被替换）
:: 纯 PowerShell 实现 asar 解包/打包，无需 Node.js
:: ============================================================
#===PS1_START===
$Action = '@@BATCH_ACTION@@'

$asar = "@@DMGHG_DIR@@resources\app.asar"
$backup = "$asar.bak"
$extractDir = "$env:TEMP\dmghg-patch-4k"

$silent = ($Action -eq "startup")

function Log {
    param($m)
    if (-not $silent) { Write-Output $m }
}

# ============ ASAR 提取函数 ============
function Extract-Asar {
    param([string]$AsarPath, [string]$OutputDir)
    $bytes = [System.IO.File]::ReadAllBytes($AsarPath)
    $headerBufLen = [System.BitConverter]::ToUInt32($bytes, 4)
    $jsonLen = [System.BitConverter]::ToUInt32($bytes, 12)
    $jsonStr = [System.Text.Encoding]::UTF8.GetString($bytes, 16, $jsonLen)
    $header = $jsonStr | ConvertFrom-Json
    $contentStart = 8 + $headerBufLen
    function Walk-Tree($Node, $ParentPath) {
        foreach ($name in $Node.PSObject.Properties.Name) {
            $child = $Node.$name
            if ($child.PSObject.Properties.Name -contains "files") {
                $dirPath = Join-Path $ParentPath $name
                New-Item -ItemType Directory -Path $dirPath -Force | Out-Null
                Walk-Tree $child.files $dirPath
            } else {
                $filePath = Join-Path $ParentPath $name
                $offset = $contentStart + [long]$child.offset
                $size = [long]$child.size
                if ($size -gt 0) {
                    [System.IO.File]::WriteAllBytes($filePath, $bytes[$offset..($offset+$size-1)])
                } else {
                    [System.IO.File]::WriteAllBytes($filePath, @())
                }
            }
        }
    }
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
    Walk-Tree $header.files $OutputDir
}

# ============ ASAR 打包函数 ============
function Pack-Asar {
    param([string]$InputDir, [string]$AsarPath)

    # 收集所有文件（按目录层级排序）
    $allFiles = [System.Collections.ArrayList]@()
    function Collect-Files($Dir, $Prefix) {
        Get-ChildItem $Dir | Sort-Object Name | ForEach-Object {
            if ($_.PSIsContainer) {
                Collect-Files $_.FullName "$Prefix/$($_.Name)"
            } else {
                [void]$allFiles.Add(@{
                    Path = $_.FullName
                    RelPath = "$Prefix/$($_.Name)"
                    Size = $_.Length
                    Offset = 0
                })
            }
        }
    }
    Collect-Files $InputDir ""

    # 构建 JSON 文件树
    function Build-JsonTree {
        $tree = [ordered]@{}
        foreach ($f in $allFiles) {
            $parts = $f.RelPath.TrimStart("/") -split "/"
            $cur = $tree
            for ($i = 0; $i -lt $parts.Count; $i++) {
                $p = $parts[$i]
                if ($i -eq $parts.Count - 1) {
                    $cur[$p] = [ordered]@{ size = $f.Size; offset = "$($f.Offset)" }
                } else {
                    if (-not $cur.Contains($p)) { $cur[$p] = [ordered]@{ files = [ordered]@{} } }
                    $cur = $cur[$p].files
                }
            }
        }
        return $tree
    }

    # 迭代计算偏移量（偏移量影响 JSON 长度，JSON 长度影响偏移量，需收敛）
    $prevPaddedLen = -1
    $paddedPayloadLen = 0
    $headerBufLen = 0
    $jsonStr = ""

    for ($iter = 0; $iter -lt 10; $iter++) {
        $jsonTree = [ordered]@{ files = Build-JsonTree }
        $jsonStr = $jsonTree | ConvertTo-Json -Depth 100 -Compress
        $jsonBytes = [System.Text.Encoding]::UTF8.GetBytes($jsonStr)

        $payloadLen = 4 + $jsonBytes.Length
        $paddedPayloadLen = ($payloadLen + 3) -band -bnot 3
        $headerBufLen = 4 + $paddedPayloadLen
        $contentStart = 8 + $headerBufLen

        # 分配实际偏移量
        $off = 0
        foreach ($f in $allFiles) {
            $f.Offset = $off
            $off += $f.Size
        }

        if ($paddedPayloadLen -eq $prevPaddedLen) { break }
        $prevPaddedLen = $paddedPayloadLen
    }

    # 写入 asar 文件
    $fs = [System.IO.File]::OpenWrite($AsarPath)
    $w = [System.IO.BinaryWriter]::new($fs)

    # sizeBuf: [uint32:4][uint32:headerBufLen]
    $w.Write([uint32]4)
    $w.Write([uint32]$headerBufLen)

    # headerBuf: [uint32:paddedPayloadLen][uint32:jsonLen][json bytes][padding]
    $jsonBytes = [System.Text.Encoding]::UTF8.GetBytes($jsonStr)
    $w.Write([uint32]$paddedPayloadLen)
    $w.Write([uint32]$jsonBytes.Length)
    $w.Write($jsonBytes)
    $pad = $paddedPayloadLen - (4 + $jsonBytes.Length)
    if ($pad -gt 0) { $w.Write([byte[]]::new($pad)) }

    # 写入文件内容
    foreach ($f in $allFiles) {
        if ($f.Size -gt 0) {
            $data = [System.IO.File]::ReadAllBytes($f.Path)
            $w.Write($data)
        }
    }

    $w.Flush()
    $w.Close()
    $fs.Close()
}

# ============ 主逻辑 ============

# 恢复模式
if ($Action -eq "restore") {
    Log "恢复原始文件..."
    if (Test-Path $backup) {
        Remove-Item -Force $asar -ErrorAction SilentlyContinue
        Copy-Item $backup $asar
        Remove-Item -Force $backup
        Log "[OK] 已恢复原始 app.asar"
        exit 0
    } else {
        Log "[ERROR] 未找到备份文件"
        exit 1
    }
}

# 检查是否已修补
Remove-Item -Recurse -Force $extractDir -ErrorAction SilentlyContinue

Log "正在解包 asar..."
try {
    Extract-Asar $asar $extractDir
} catch {
    Log "[ERROR] asar 解包失败: $_"
    exit 1
}

$indexJs = "$extractDir\out\main\index.js"
$alreadyPatched = (Test-Path $indexJs) -and (Select-String -Path $indexJs -Pattern "__videoCache" -SimpleMatch -Quiet)

if (-not $alreadyPatched) {
    Log "-> 备份原始文件..."
    Copy-Item $asar $backup -Force

    Log "-> 解除 4K VIP 限制 + 视频缓存（无缝切换）..."

    $content = [System.IO.File]::ReadAllText($indexJs)
    $content = $content -replace 'const Users = \{\s*isVip:\s*\(cid\)\s*=>\s*\{[^}]*\}[^}]*\};', 'const Users = { isVip: (cid) => { return true; } };'
    $content = $content.Replace('class VideoApi {', 'const __videoCache = new Map(); class VideoApi {')
    $content = $content.Replace('    if (code === RUST_LEGACY_OK) {', '    if (code === RUST_LEGACY_OK) { __videoCache.set(id, data2);')
    $content = $content.Replace('    } else if (code === 403101 || code === 500403) {', '    } else if (code === 403101 || code === 500403) { var _c=__videoCache.get(id);if(_c){return VideoUrlLoader(_c,args)}')
    [System.IO.File]::WriteAllText($indexJs, $content)

    Log "-> 屏蔽聚点APP弹窗..."

    Get-ChildItem "$extractDir\out\renderer\assets\*.js" | ForEach-Object {
        try {
            $pc = [System.IO.File]::ReadAllText($_.FullName)
            if ($pc.Contains("store.visible.paid = true")) {
                $pc = $pc -replace 'if\s*\(\s*args\?\s*\.\s*action\s*&&\s*args\s*\.\s*action\s*===\s*"buy"\s*\)\s*\{\s*store\.visible\.paid\s*=\s*true;\s*\}', 'if (false) {}'
                [System.IO.File]::WriteAllText($_.FullName, $pc)
            }
        } catch {}
    }

    Log "-> 重新打包..."
    try {
        Remove-Item -Force $asar -ErrorAction SilentlyContinue
        Pack-Asar $extractDir $asar
        Remove-Item -Recurse -Force $extractDir -ErrorAction SilentlyContinue
        Log "[OK] 4K 解锁 + 无缝切换 + 弹窗屏蔽 已就绪"
    } catch {
        # 打包失败，尝试恢复
        Log "[ERROR] 打包失败: $_"
        if (Test-Path $backup) {
            Copy-Item $backup $asar -Force
            Log "已从备份恢复"
        }
        exit 1
    }
} else {
    Log "[OK] 补丁已存在，无需重复操作"
    Remove-Item -Recurse -Force $extractDir -ErrorAction SilentlyContinue
}

exit 0
#===PS1_END===
