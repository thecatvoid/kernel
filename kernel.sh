#!/bin/bash
set -e

# Misc functions
die() {
        if [[ -z "$@" ]]
        then printf "%s\n" "Error" >&2
        else printf "%s\n" "Error: ${@}" >&2
        fi
        return 1
}

cd() {
        command cd "$@" || die "Couldn't cd to $@"
}

home() {
        cd "$HOME"
}

compile() {
        make -j"$(nproc --all)" "$@"
}

# Main functions
setup_build() {
        home
        apt update
        apt install -y \
                git curl lz4 linux-headers-amd64 binutils-dev \
                build-essential gcc bc libncurses5-dev \
                libssl-dev bison flex gcc-multilib libelf-dev \
                fakeroot wireless-regdb gzip xz-utils \
                binutils-common rsync

        [[ ! -d ./linux-firmware ]] && git clone --depth=1 "https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git"
        rsync -a --ignore-existing linux-firmware/* /lib/firmware
        cp -f ./intel-ucode/* /lib/firmware/
        [[ ! -d ./linux ]] && git clone --depth=1 "https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git" ./linux
        cd linux
        version=$(grep "^VERSION" Makefile | awk '{print $3}')
        patchlevel=$(grep "^PATCHLEVEL" Makefile | awk '{print $3}')
        ver="$version.$patchlevel"
        curl -sS "https://raw.githubusercontent.com/archlinux/svntogit-packages/packages/linux/trunk/config" -o .config
        compile savedefconfig
        sed -i -e '/CONFIG_MODULE/d' \
                -e '/INITRD/d' \
                -e '/INITRAMFS/d' \
                -e 's/=m/=y/' \
                -e '/CONFIG_KERNEL_/d' \
                -e '/CONFIG_EXTRA_FIRMWARE/d' defconfig

        echo 'CONFIG_EXTRA_FIRMWARE="regulatory.db regulatory.db.p7s rtlwifi/rtl8188efw.bin 06-3c-03"' >> defconfig
        echo 'CONFIG_KERNEL_XZ=y' >> defconfig
        cp -f defconfig arch/x86/configs/linux_defconfig
}

build() {
        home
        cd linux
        compile linux_defconfig
        compile || make -j1
}

# Call functions as command line arguments
for cmd; do $cmd; done
