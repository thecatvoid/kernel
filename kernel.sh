#!/bin/bash
set -e
flags=(
        IGNORE_CC_MISMATCH='1'
        CC='gcc-13'
        AS='as'
        CFLAGS='-march=haswell -mtune=haswell -mcmodel=small -O2 -pipe -ftree-vectorize -fprofile-generate -fomit-frame-pointer -fno-ident'
        ARCH='x86'
        SUBARCH='x86'
        AR='gcc-ar-13'
        RANLIB='gcc-ranlib-13'
        LD='ld'
        KBUILD_LDFLAGS=''
        ARCH='x86'
        NM='gcc-nm-13'
        OBJCOPY='objcopy'
        READELF='readelf'
        HOSTCC='gcc-13'
        OBJSIZE='size'
        OBJDUMP='objdump'
        STRIP='strip'
        READELF='readelf'
        HOSTAR='gcc-ar-13'
        HOSTLD='ld'
)
declare -g "${flags[@]}"
export "${flags[@]}"

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
        make "${flags[@]}" -j"$(nproc --all)" "$@"
}

# Main functions
setup_build() {
        home
        apt update
        apt install -t experimental -y \
                bc make libncurses5-dev libssl-dev \
                bison binutils-common binutils flex libelf-dev \
                gcc-13 gcc-13-base gcc-13-multilib gcc-13-plugin-dev \
                libgcc-13-dev binutils-dev gzip xz-utils curl \
                fakeroot wireless-regdb lz4 git busybox-static zstd cpio

        [[ -d ./linux ]] && git clone --depth=1 https://github.com/zen-kernel/zen-kernel ./linux
        cp -f linux_defconfig ./linux/arch/x86/configs/linux_defconfig

        cd linux
        version=$(grep "^VERSION" Makefile | awk '{print $3}')
        patchlevel=$(grep "^PATCHLEVEL" Makefile | awk '{print $3}')
        ver="$version.$patchlevel"
        git clone --depth=1 https://github.com/xanmod/linux-patches xanmod
        git clone --depth=1 https://github.com/Frogging-Family/linux-tkg tkg
        find xanmod/*"${ver}"* tkg/linux-tkg-patches/"$ver" -name "*.patch" -type f |
                grep -vE "net|userns|sysctl" | xargs -I{} patch -p1 -N < {} || true
}

build() {
        home
        cd linux
        compile linux_defconfig
        compile
}

# Call functions as command line arguments
for cmd; do cmd; done
