#!/usr/bin/env just --justfile

# CONFIG
cc_path := "/home/gcc-arm/gcc/bin/"
rkbin_path := "../rkbin"
arch := "arm"
cross_compile_prefix := "arm-linux-gnueabihf-"
parallels := "24"
defconfig := "rk3506_luckfox_defconfig"
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

all: defcfg build mk_img mk_dtbs
	@echo "Complete kernel build finished!"
menuconfig:
	make menuconfig ARCH={{arch}} CROSS_COMPILE={{cross_compile_prefix}}
	
clean:
	make clean ARCH={{arch}} CROSS_COMPILE={{cross_compile_prefix}}
