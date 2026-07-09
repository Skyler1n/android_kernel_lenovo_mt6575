#!/bin/bash
# MT6575 Lenovo A60+ kernel build runner
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TOOLCHAIN_DIR="$SCRIPT_DIR/prebuilt/linux-x86/toolchain/arm-linux-androideabi-4.4.3"

export PATH="$TOOLCHAIN_DIR/bin:$PATH"
export TARGET_PRODUCT=huaqin75cu_nbd_lca_gb2
export MTK_ROOT_CUSTOM="$SCRIPT_DIR/mediatek/custom/"
export MAKEJOBS=-j8

cd "$SCRIPT_DIR/kernel" || exit 99

echo "==== ENV CHECK ===="
echo "PATH=$PATH"
which arm-eabi-gcc || { echo "NO CROSS COMPILER"; exit 98; }
echo "Cross compiler: $(arm-eabi-gcc --version | head -1)"
echo "Kernel dir: $(pwd)"
echo "================"

./build.sh huaqin75cu_nbd_lca_gb2
rc=$?
echo "==== build.sh exit code: $rc ===="
echo "==== output artifacts ===="
ls -la arch/arm/boot/zImage arch/arm/boot/Image kernel_huaqin75cu_nbd_lca_gb2.bin rootfs_huaqin75cu_nbd_lca_gb2.bin 2>/dev/null
echo "==== DONE rc=$rc ===="
