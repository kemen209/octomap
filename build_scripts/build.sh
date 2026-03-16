#!/usr/bin/env bash
# 构建 octomap 的 Debug 与 Release 共享库，并安装到本地目录供外部项目使用。
# 参考: https://github.com/OctoMap/octomap

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
# 构建与安装输出目录（可在调用前通过环境变量覆盖）
BUILD_ROOT="${BUILD_ROOT:-$SCRIPT_DIR}"
INSTALL_PREFIX="${INSTALL_PREFIX:-$SCRIPT_DIR}"
OCTOMAP_SOURCE="$REPO_ROOT/octomap"

echo "=== OctoMap 构建 (Debug + Release 共享库) ==="
echo "  源码: $OCTOMAP_SOURCE"
echo "  构建目录: $BUILD_ROOT"
echo "  安装前缀: $INSTALL_PREFIX"
echo ""

build_one() {
  local config="$1"
  local config_lower
  config_lower=$(echo "$config" | tr '[:upper:]' '[:lower:]')
  local build_dir="$BUILD_ROOT/build-$config_lower"
  local install_dir="$INSTALL_PREFIX/install-$config_lower"

  echo "--- 配置并构建: $config ---"
  mkdir -p "$build_dir"
  cd "$build_dir"
  cmake "$OCTOMAP_SOURCE" \
    -DCMAKE_BUILD_TYPE="$config" \
    -DBUILD_SHARED_LIBS=ON \
    -DCMAKE_INSTALL_PREFIX="$install_dir" \
    -DBUILD_TESTING=OFF
  cmake --build . -j"${JOBS:-$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)}"
  cmake --install .
  cd "$SCRIPT_DIR"
  echo "  已安装到: $install_dir"
  echo ""
}

build_one "Release"
build_one "Debug"

echo "=== 构建完成 ==="
echo "  Release: $INSTALL_PREFIX/install-release"
echo "  Debug:   $INSTALL_PREFIX/install-debug"
echo ""
echo "外部项目使用方式："
echo "  Release: cmake -DCMAKE_PREFIX_PATH=$INSTALL_PREFIX/install-release ..."
echo "  Debug:   cmake -DCMAKE_PREFIX_PATH=$INSTALL_PREFIX/install-debug ..."
