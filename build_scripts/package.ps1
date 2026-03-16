# 在 Windows 上按 repo/lib 约定打包：Release 含 includes + 库，Debug 仅库（无头文件）。
# 输出: <DIST_DIR>\windows_x64_release\octomap_<version>.zip
#       <DIST_DIR>\windows_x64_debug\octomap_<version>_d.zip
# 用法: 先运行 .\build.ps1，再运行 .\package.ps1。

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir
$InstallPrefix = if ($env:INSTALL_PREFIX) { $env:INSTALL_PREFIX } else { $ScriptDir }
$DIST_DIR = if ($env:DIST_DIR) { $env:DIST_DIR } else { Join-Path $ScriptDir "dist" }
$OCTOMAP_SOURCE = Join-Path $RepoRoot "octomap"

# 从 octomap 的 CMakeLists.txt 解析版本号
$versionLine = Get-Content (Join-Path $OCTOMAP_SOURCE "CMakeLists.txt") | Select-String -Pattern 'VERSION\s+([0-9.]+)' | Select-Object -First 1
$VERSION = if ($versionLine -match 'VERSION\s+([0-9.]+)') { $Matches[1] } else { "1.10.0" }

$PLATFORM = "windows_x64"
$RELEASE_DIR = Join-Path $InstallPrefix "install-release"
$DEBUG_DIR = Join-Path $InstallPrefix "install-debug"
$RELEASE_OUT = Join-Path $DIST_DIR "${PLATFORM}_release"
$DEBUG_OUT = Join-Path $DIST_DIR "${PLATFORM}_debug"
$PACK_DIR = Join-Path $ScriptDir ".pack"
$PACK_RELEASE = Join-Path $PACK_DIR "release"
$PACK_DEBUG = Join-Path $PACK_DIR "debug"

Write-Host "=== OctoMap 打包 (repo/lib 格式) [Windows] ===" -ForegroundColor Cyan
Write-Host "  版本: $VERSION"
Write-Host "  平台: $PLATFORM"
Write-Host "  输出: $RELEASE_OUT, $DEBUG_OUT"
Write-Host ""

foreach ($dir in @($RELEASE_DIR, $DEBUG_DIR)) {
    if (-not (Test-Path $dir)) {
        Write-Host "错误: 未找到 $dir，请先执行 .\build.ps1" -ForegroundColor Red
        exit 1
    }
}

if (Test-Path $PACK_DIR) { Remove-Item $PACK_DIR -Recurse -Force }
New-Item -ItemType Directory -Path $PACK_RELEASE -Force | Out-Null
New-Item -ItemType Directory -Path $PACK_DEBUG -Force | Out-Null
foreach ($d in @($RELEASE_OUT, $DEBUG_OUT)) {
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
}

# Release: includes/ + 所有库（.dll 通常在 bin，.lib 在 lib）放在归档根目录
$releaseInclude = Join-Path $RELEASE_DIR "include"
Copy-Item -Path $releaseInclude -Destination (Join-Path $PACK_RELEASE "includes") -Recurse -Force
foreach ($sub in @("bin", "lib")) {
    $dir = Join-Path $RELEASE_DIR $sub
    if (Test-Path $dir) {
        Get-ChildItem -Path $dir -File | Where-Object { $_.Extension -match '\.(dll|lib)$' } | ForEach-Object { Copy-Item $_.FullName -Destination $PACK_RELEASE -Force }
    }
}

# Debug: 仅 .dll、.lib、.pdb（无头文件）
foreach ($sub in @("bin", "lib")) {
    $dir = Join-Path $DEBUG_DIR $sub
    if (Test-Path $dir) {
        Get-ChildItem -Path $dir -File | Where-Object { $_.Extension -match '\.(dll|lib|pdb)$' } | ForEach-Object { Copy-Item $_.FullName -Destination $PACK_DEBUG -Force }
    }
}

# 打 Release 包：includes/ + 根目录下所有库
$releaseZip = Join-Path $RELEASE_OUT "octomap_$VERSION.zip"
if (Test-Path $releaseZip) { Remove-Item $releaseZip -Force }
Compress-Archive -Path (Join-Path $PACK_RELEASE "*") -DestinationPath $releaseZip -CompressionLevel Optimal
Write-Host "已生成: $releaseZip" -ForegroundColor Green

# 打 Debug 包：仅库
$debugZip = Join-Path $DEBUG_OUT "octomap_${VERSION}_d.zip"
if (Test-Path $debugZip) { Remove-Item $debugZip -Force }
Compress-Archive -Path (Join-Path $PACK_DEBUG "*") -DestinationPath $debugZip -CompressionLevel Optimal
Write-Host "已生成: $debugZip" -ForegroundColor Green

Remove-Item $PACK_DIR -Recurse -Force -ErrorAction SilentlyContinue
Write-Host ""
Write-Host "=== 打包完成 ===" -ForegroundColor Cyan
Write-Host "  复制到 repo/lib: Copy-Item `"$releaseZip`" `"/path/to/repo/lib/${PLATFORM}_release/`""
Write-Host "                  Copy-Item `"$debugZip`" `"/path/to/repo/lib/${PLATFORM}_debug/`""
Write-Host ""
