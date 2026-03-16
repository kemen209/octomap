#!/usr/bin/env bash
# 按 repo/lib 约定打包：Release 含 includes + 库，Debug 仅库（无头文件）。
# 输出: <DIST_DIR>/<platform>_release/octomap_<version>.tar.gz
#       <DIST_DIR>/<platform>_debug/octomap_<version>_d.tar.gz
# 用法: 先运行 ./build.sh，再运行 ./package.sh。

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
INSTALL_PREFIX="${INSTALL_PREFIX:-$SCRIPT_DIR}"
DIST_DIR="${DIST_DIR:-$SCRIPT_DIR/dist}"
OCTOMAP_SOURCE="$REPO_ROOT/octomap"

# 从 octomap 的 CMakeLists.txt 解析版本号
VERSION=$(sed -n 's/^project([^)]*VERSION \([0-9.]*\).*/\1/p' "$OCTOMAP_SOURCE/CMakeLists.txt" | head -1)
if [[ -z "$VERSION" ]]; then
  VERSION="1.10.0"
fi

# 平台与库后缀（与 repo/lib 一致：osx_x64_release, osx_x64_debug）
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)
case "$OS" in
  darwin)
    case "$ARCH" in
      x86_64) PLATFORM="osx_x64" ;;
      arm64)  PLATFORM="osx_arm64" ;;
      *)      PLATFORM="osx_${ARCH}" ;;
    esac
    LIB_EXT="dylib"
    ;;
  linux)
    PLATFORM="linux_${ARCH}"
    LIB_EXT="so"
    ;;
  *)
    PLATFORM="${OS}_${ARCH}"
    LIB_EXT="so"
    ;;
esac

RELEASE_DIR="$INSTALL_PREFIX/install-release"
DEBUG_DIR="$INSTALL_PREFIX/install-debug"
RELEASE_OUT="$DIST_DIR/${PLATFORM}_release"
DEBUG_OUT="$DIST_DIR/${PLATFORM}_debug"
PACK_DIR="$SCRIPT_DIR/.pack"
PACK_RELEASE="$PACK_DIR/release"
PACK_DEBUG="$PACK_DIR/debug"

echo "=== OctoMap 打包 (repo/lib 格式) ==="
echo "  版本: $VERSION"
echo "  平台: $PLATFORM"
echo "  输出: $RELEASE_OUT, $DEBUG_OUT"
echo ""

for dir in "$RELEASE_DIR" "$DEBUG_DIR"; do
  if [[ ! -d "$dir" ]]; then
    echo "错误: 未找到 $dir，请先执行 ./build.sh"
    exit 1
  fi
done

rm -rf "$PACK_DIR"
mkdir -p "$PACK_RELEASE" "$PACK_DEBUG" "$RELEASE_OUT" "$DEBUG_OUT"

# Release: includes/ + 所有共享库（放在归档根目录）
cp -a "$RELEASE_DIR/include" "$PACK_RELEASE/includes"
for f in "$RELEASE_DIR/lib"/lib*."$LIB_EXT"*; do
  [[ -e "$f" ]] || continue
  cp -a "$f" "$PACK_RELEASE/"
done

# Debug: 仅共享库（无头文件）
for f in "$DEBUG_DIR/lib"/lib*."$LIB_EXT"*; do
  [[ -e "$f" ]] || continue
  cp -a "$f" "$PACK_DEBUG/"
done

# 打 Release 包：includes/ + 根目录下所有 lib* 库（与 protobuf 一致）
(cd "$PACK_RELEASE" && tar czf "$RELEASE_OUT/octomap_${VERSION}.tar.gz" includes lib*)
echo "已生成: $RELEASE_OUT/octomap_${VERSION}.tar.gz"

# 打 Debug 包：仅 lib* 库（无头文件）
(cd "$PACK_DEBUG" && tar czf "$DEBUG_OUT/octomap_${VERSION}_d.tar.gz" lib*)
echo "已生成: $DEBUG_OUT/octomap_${VERSION}_d.tar.gz"

rm -rf "$PACK_DIR"
echo ""
echo "=== 打包完成 ==="
echo "  复制到 repo/lib: cp $RELEASE_OUT/octomap_${VERSION}.tar.gz /path/to/repo/lib/${PLATFORM}_release/"
echo "                  cp $DEBUG_OUT/octomap_${VERSION}_d.tar.gz /path/to/repo/lib/${PLATFORM}_debug/"
echo ""
