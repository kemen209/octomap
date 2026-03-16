# OctoMap 构建与打包脚本

用于将 octomap 编译为 **Debug** 和 **Release** 共享库，并按 **repo/lib** 约定打包（与 protobuf 等一致）。构建方式遵循 [官方说明](https://github.com/OctoMap/octomap)。

- **Unix/macOS**：`build.sh` + `package.sh` → 生成 `.tar.gz`，目录 `osx_x64_*` / `linux_*`。
- **Windows**：`build.ps1` + `package.ps1` → 生成 `.zip`，目录 `windows_x64_release` / `windows_x64_debug`。

## 用法

**Unix / macOS / Linux：**
```bash
./build.sh
./package.sh
```

**Windows（在「适用于 VS 的 x64 本机工具」或已加载 VS 环境的 PowerShell 中）：**
```powershell
.\build.ps1
.\package.ps1
```

## 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `BUILD_ROOT` | `build_scripts/` | 构建目录（build-release、build-debug） |
| `INSTALL_PREFIX` | `build_scripts/` | 安装根目录（其下为 install-release、install-debug） |
| `DIST_DIR` | `build_scripts/dist` | 打包输出根目录（package.sh / package.ps1） |
| `JOBS` | 自动检测 | 并行编译数（仅 Unix） |

**仅 Windows（PowerShell）：**
| 变量 | 默认值 | 说明 |
|------|--------|------|
| `CMAKE_GENERATOR` | `Visual Studio 17 2022` | CMake 生成器 |
| `CMAKE_ARCH` | `x64` | 目标架构 |

示例（Unix）：安装到自定义目录并打包到 repo/lib：
```bash
INSTALL_PREFIX=/opt/octomap ./build.sh
DIST_DIR=/path/to/repo/lib INSTALL_PREFIX=/opt/octomap ./package.sh
```

示例（Windows）：
```powershell
$env:INSTALL_PREFIX = "D:\octomap"; .\build.ps1
$env:DIST_DIR = "K:\repo\lib"; $env:INSTALL_PREFIX = "D:\octomap"; .\package.ps1
```

## 打包输出（与 repo/lib 一致）

- **目录**：`<DIST_DIR>/<platform>_release/`、`<DIST_DIR>/<platform>_debug/`  
  - Unix：平台示例 `osx_x64`、`osx_arm64`、`linux_x86_64`。  
  - Windows：`windows_x64_release`、`windows_x64_debug`。
- **Release**：  
  - Unix：`octomap_<version>.tar.gz` → **includes/** + 根目录 **lib*.dylib / lib*.so**。  
  - Windows：`octomap_<version>.zip` → **includes/** + 根目录 **.dll、.lib**（来自 install 的 bin/、lib/）。
- **Debug**：  
  - Unix：`octomap_<version>_d.tar.gz` → 仅根目录库文件。  
  - Windows：`octomap_<version>_d.zip` → 仅根目录 **.dll、.lib、.pdb**，**无头文件**。

复制到 repo/lib 后即可与现有 protobuf 等包并列使用：

```bash
# Unix
cp build_scripts/dist/osx_x64_release/octomap_1.10.0.tar.gz   /path/to/repo/lib/osx_x64_release/
cp build_scripts/dist/osx_x64_debug/octomap_1.10.0_d.tar.gz  /path/to/repo/lib/osx_x64_debug/
```

```powershell
# Windows
Copy-Item build_scripts\dist\windows_x64_release\octomap_1.10.0.zip   K:\repo\lib\windows_x64_release\
Copy-Item build_scripts\dist\windows_x64_debug\octomap_1.10.0_d.zip   K:\repo\lib\windows_x64_debug\
```

## 在外部项目中使用（未打包的安装树）

若直接使用 `install-release` / `install-debug`（含 CMake 配置）：

```bash
cmake -DCMAKE_PREFIX_PATH=/path/to/install-release ...
# 或 Debug: .../install-debug
```

CMakeLists.txt 中：

```cmake
find_package(octomap REQUIRED)
target_link_libraries(your_target PRIVATE octomap::octomap)
```
