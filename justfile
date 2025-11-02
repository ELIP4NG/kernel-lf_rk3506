#!/usr/bin/env just --justfile

# ==================== CONFIG ====================
# Toolchain Configuration
cc_path := "/home/gcc-arm/gcc/bin/"
cross_compile_prefix := "arm-linux-gnueabihf-"

# Path Configuration
rkbin_path := "../rkbin"

# Architecture Configuration
arch := "arm"

# Build Configuration
parallels := "24"
defconfig := "rk3506_luckfox_defconfig"

# Device Tree Configuration (for reference/testing)
# For Luckfox Lyra Pi SD card version
dtb_name := "rk3506b-luckfox-lyra-pi-sd.dtb"
# Other available DTBs:
# - rk3506b-luckfox-lyra-pi.dtb
# - rk3506b-luckfox-lyra-pi-w.dtb
# - rk3506b-luckfox-lyra-pi-w-sd.dtb
# - rk3506b-luckfox-lyra-zero-w.dtb
# - rk3506b-luckfox-lyra-zero-w-sd.dtb
# - rk3506b-luckfox-lyra-ultra-w.dtb
# ======

jfdir := replace(justfile_directory(), "\\", "/")
cc_path_abs := if cc_path =~ "^/" { clean(cc_path) } else { clean(jfdir / cc_path) }
parallel_flag := "-j" + parallels
log_dir := jfdir / "logs"
log_filename := "build-log-" + `date +'%Y-%m%d-%H%M-%S'` + ".log"
log_file := log_dir / log_filename
origin_path := env_var("PATH")
new_path := cc_path_abs + ":" + origin_path
kmod_out_path := jfdir / "out-modules"

export PATH := new_path

alias b := build
alias m := menuconfig
alias c := clean

default:
	just --list
	@echo "==== INFO ===="
	@echo "cc_path_abs={{cc_path_abs}}"
	@echo "parallel_flag={{parallel_flag}}"
	@echo "cross_compile_prefix={{cross_compile_prefix}}"
	@echo "log_file={{log_file}}"

defcfg:
	mkdir -p {{log_dir}}
	make ARCH={{arch}} CROSS_COMPILE={{cross_compile_prefix}} {{defconfig}}  2>&1 | tee {{log_file}}

build:
	mkdir -p {{log_dir}}
	make {{parallel_flag}} ARCH={{arch}} CROSS_COMPILE={{cross_compile_prefix}} 2>&1 | tee {{log_file}}

# Build from scratch: clean + defconfig + build
# WARNING: This will reset .config to defaults!
from-scratch:
	mkdir -p {{log_dir}}
	make mrproper
	just defcfg
	just build

mk_kmod:
	mkdir -p {{log_dir}}
	mkdir -p {{kmod_out_path}}
	make modules {{parallel_flag}} ARCH={{arch}} CROSS_COMPILE={{cross_compile_prefix}} INSTALL_MOD_PATH={{kmod_out_path}}  2>&1 | tee {{log_file}}
	make modules_install {{parallel_flag}} ARCH={{arch}} CROSS_COMPILE={{cross_compile_prefix}} INSTALL_MOD_PATH={{kmod_out_path}}  2>&1 | tee {{log_file}}

mk_img:
	mkdir -p {{log_dir}}
	make zImage {{parallel_flag}} ARCH={{arch}} CROSS_COMPILE={{cross_compile_prefix}} 2>&1 | tee {{log_file}}

mk_image:
	mkdir -p {{log_dir}}
	make Image {{parallel_flag}} ARCH={{arch}} CROSS_COMPILE={{cross_compile_prefix}} 2>&1 | tee {{log_file}}

mk_dtbs:
	mkdir -p {{log_dir}}
	make dtbs {{parallel_flag}} ARCH={{arch}} CROSS_COMPILE={{cross_compile_prefix}} 2>&1 | tee {{log_file}}

mk_dtb dtb_file:
	mkdir -p {{log_dir}}
	make {{dtb_file}} {{parallel_flag}} ARCH={{arch}} CROSS_COMPILE={{cross_compile_prefix}} 2>&1 | tee {{log_file}}

check_dtb:
	@echo "Checking if {{dtb_name}} was built..."
	@if [ -f arch/{{arch}}/boot/dts/{{dtb_name}} ]; then \
		ls -lh arch/{{arch}}/boot/dts/{{dtb_name}}; \
		echo "✓ DTB found and ready"; \
	else \
		echo "✗ DTB not found. Run 'just mk_dtbs' first"; \
		exit 1; \
	fi

show_size:
	#!/usr/bin/env bash
	echo "==== Kernel Image Size ===="
	if [ -f arch/{{arch}}/boot/Image ]; then
		size=$(ls -lh arch/{{arch}}/boot/Image | awk '{print $5}')
		echo "Image (uncompressed): $size"
	else
		echo "Image not found"
	fi
	if [ -f arch/{{arch}}/boot/zImage ]; then
		size=$(ls -lh arch/{{arch}}/boot/zImage | awk '{print $5}')
		echo "zImage (compressed):   $size"
	else
		echo "zImage not found"
	fi
	echo "==========================="

# NOTE: Do NOT include 'defcfg' in 'all' recipe to avoid overwriting manually modified .config
# The 'all' recipe is for DAILY USE - it preserves .config and does incremental builds
# Use 'just defcfg' separately only when you need to reset to default configuration
# Or use 'just from-scratch' at project root for complete clean rebuild
all: build mk_img mk_dtbs show_size
	@echo "Complete kernel build finished!"

# Interactive configuration editor
# WARNING: This modifies .config - use with caution!
menuconfig:
	make menuconfig ARCH={{arch}} CROSS_COMPILE={{cross_compile_prefix}}
	
clean:
	make clean ARCH={{arch}} CROSS_COMPILE={{cross_compile_prefix}}
