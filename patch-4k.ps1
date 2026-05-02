$asar = "D:\APP\dmghg\resources\app.asar"
$extractDir = "D:\APP\dmghg\resources\app-extracted"
$indexJs = "$extractDir\out\main\index.js"

if (-not (Test-Path $asar)) {
    exit 0
}

# 检查是否已经打过补丁（解包检查）
$tempDir = "$env:TEMP\dmghg-patch-check"
if (Test-Path $tempDir) { Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue }
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

npx asar extract $asar $tempDir 2>$null
$checkFile = "$tempDir\out\main\index.js"
$alreadyPatched = (Select-String -Path $checkFile -Pattern "return true" -SimpleMatch -Quiet)

Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue

if ($alreadyPatched) {
    exit 0
}

# 需要打补丁
Write-Output "dmghg: 检测到 app.asar 已更新，正在解除4K限制..."

New-Item -ItemType Directory -Path $extractDir -Force | Out-Null
npx asar extract $asar $extractDir 2>$null

$content = [System.IO.File]::ReadAllText($indexJs)
$content = $content -replace 'const Users = \{\s*isVip:\s*\(cid\)\s*=>\s*\{[^}]*\}[^}]*\};', 'const Users = { isVip: (cid) => { return true; } };'
[System.IO.File]::WriteAllText($indexJs, $content)

Remove-Item -Force $asar -ErrorAction SilentlyContinue
npx asar pack $extractDir $asar 2>$null

Remove-Item -Recurse -Force $extractDir -ErrorAction SilentlyContinue

Write-Output "dmghg: 4K限制已解除！"
