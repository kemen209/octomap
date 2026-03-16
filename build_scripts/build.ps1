# 在 Windows 上构建 octomap 的 Debug 与 Release 共享库，并安装到本地目录供外部项目使用。
# 需在「适用于 VS 的 x64 本机工具」或 PowerShell 中已加载 VS 环境后执行。
# 参考: https://github.com/OctoMap/octomap

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir
$BuildRoot = if ($env:BUILD_ROOT) { $env:BUILD_ROOT } else { $ScriptDir }
$InstallPrefix = if ($env:INSTALL_PREFIX) { $env:INSTALL_PREFIX } else { $ScriptDir }
$OCTOMAP_SOURCE = Join-Path $RepoRoot "octomap"

# 可选：指定 VS 生成器，例如 "Visual Studio 17 2022" -A x64 或 "Visual Studio 16 2019" -A x64
$Generator = if ($env:CMAKE_GENERATOR) { $env:CMAKE_GENERATOR } else { "Visual Studio 17 2022" }
$Arch = if ($env:CMAKE_ARCH) { $env:CMAKE_ARCH } else { "x64" }

Write-Host "=== OctoMap 构建 (Debug + Release 共享库) [Windows] ===" -ForegroundColor Cyan
Write-Host "  源码: $OCTOMAP_SOURCE"
Write-Host "  构建目录: $BuildRoot"
Write-Host "  安装前缀: $InstallPrefix"
Write-Host ""

function Build-One {
    param([string]$Config)
    $configLower = $Config.ToLowerInvariant()
    $buildDir = Join-Path $BuildRoot "build-$configLower"
    $installDir = Join-Path $InstallPrefix "install-$configLower"

    Write-Host "--- 配置并构建: $Config ---" -ForegroundColor Yellow
    if (-not (Test-Path $buildDir)) { New-Item -ItemType Directory -Path $buildDir -Force | Out-Null }
    Push-Location $buildDir
    try {
        cmake $OCTOMAP_SOURCE `
            -G $Generator `
            -A $Arch `
            -DBUILD_SHARED_LIBS=ON `
            -DCMAKE_INSTALL_PREFIX="$installDir" `
            -DBUILD_TESTING=OFF
        if ($LASTEXITCODE -ne 0) { throw "CMake 配置失败" }
        cmake --build . --config $Config -j $env:NUMBER_OF_PROCESSORS
        if ($LASTEXITCODE -ne 0) { throw "CMake 构建失败" }
        cmake --install . --config $Config
        if ($LASTEXITCODE -ne 0) { throw "CMake 安装失败" }
        Write-Host "  已安装到: $installDir" -ForegroundColor Green
    } finally {
        Pop-Location
    }
    Write-Host ""
}

Build-One -Config "Release"
Build-One -Config "Debug"

Write-Host "=== 构建完成 ===" -ForegroundColor Cyan
$relPath = Join-Path $InstallPrefix "install-release"
$dbgPath = Join-Path $InstallPrefix "install-debug"
Write-Host "  Release: $relPath"
Write-Host "  Debug:   $dbgPath"
Write-Host ""
Write-Host "外部项目使用方式："
Write-Host "  Release: cmake -DCMAKE_PREFIX_PATH=$relPath ..."
Write-Host "  Debug:   cmake -DCMAKE_PREFIX_PATH=$dbgPath ..."
