#!/bin/bash
set -e
flags=(
       CC="clang-17"
       LLVM="1"
       LLVM_IAS="1"
       AS="llvm-as-17"
       CFLAGS="-march=haswell -mtune=haswell -O2 -pipe -ftree-vectorize -flto=full -fprofile-generate -fomit-frame-pointer -fno-ident"
       KBULD_CFLAGS="${CFLAGS}"
       ARCH="x86"
       SUBARCH="x86"
       AR="llvm-ar-17"
       RANLIB="llvm-ranlib-17"
       LD="ld.lld-17"
       NM="llvm-nm-17"
       OBJCOPY="llvm-objcopy-17"
       READELF="llvm-readelf-17"
       HOSTCC="clang-17"
       OBJSIZE="llvm-size-17"
       OBJDUMP="llvm-objdump-17"
       STRIP="llvm-strip-17"
       READELF="llvm-readelf-17"
       HOSTCXX="clang++-17"
       HOSTAR="llvm-ar-17"
       HOSTLD="ld.lld-17"
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
                git lz4 linux-headers-amd64 \
                build-essential bc libncurses5-dev libssl-dev \
                bison flex libelf-dev libclang1-17 libclang-cpp17-dev \
                libclang-cpp17 clangd-17 clang-tools-17 clang-17 \
                llvm-17-tools llvm-17 llvm-17-runtime llvm-17-dev \
                llvm-17-linker-tools lld-17 \
                fakeroot wireless-regdb xz-utils

        [[ ! -d ./linux ]] && git clone --depth=1 https://github.com/xanmod/linux ./linux
        cp -f ./linux_defconfig ./linux/arch/x86/configs/
        cd linux
        version=$(grep "^VERSION" Makefile | awk '{print $3}')
        patchlevel=$(grep "^PATCHLEVEL" Makefile | awk '{print $3}')
        ver="$version.$patchlevel"
        git clone --depth=1 https://github.com/Frogging-Family/linux-tkg tkg
        find tkg/linux-tkg-patches/"$ver" -name "*.patch" -type f |
                grep -vE "net|userns|sysctl" | while read -r i; do patch -p1 -N < "$i" || true; done
}

build() {
        home
        cd linux
        compile linux_defconfig
        compile
}

# Call functions as command line arguments
for cmd; do $cmd; done
