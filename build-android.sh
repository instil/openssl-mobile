#!/bin/bash

if [ ! ${ANDROID_NDK_HOME} ]; then
    echo "ANDROID_NDK_HOME environment variable not set, set and rerun"
    exit 1
fi

# Set directory
SCRIPTPATH=`realpath .`
OPENSSL_DIR=$SCRIPTPATH/openssl

cd "${OPENSSL_DIR}" || exit 1

# Find the toolchain for your build machine
OS_TYPE=$(uname -s | tr A-Z a-z)
ARCH=$(uname -m)
toolchains_path=/toolchains/llvm/prebuilt/$OS_TYPE-$ARCH

ANDROID_API=21
CC=clang
PATH=$toolchains_path/bin:$PATH

ANDROID_LIB_ROOT=../lib/android
rm -rf ${ANDROID_LIB_ROOT} > /dev/null

for TARGET_PLATFORM in armeabi armeabi-v7a x86 x86_64 arm64-v8a
do
    echo "Building OpenSSL for ${TARGET_PLATFORM}"
    case "${TARGET_PLATFORM}" in
        armeabi)
            architecture=android-arm
            ;;
        armeabi-v7a)
            architecture=android-arm
            ;;
        x86)
            architecture=android-x86
            ;;
        x86_64)
            architecture=android-x86_64
            ;;
        arm64-v8a)
            architecture=android-arm64
            ;;
        *)
            echo "Unsupported build platform: ${TARGET_PLATFORM}"
            exit 1
    esac

    mkdir -p "${ANDROID_LIB_ROOT}/${TARGET_PLATFORM}"

    echo "Configure"
    ./Configure ${architecture} -D__ANDROID_API__=$ANDROID_API

    if [ $? -ne 0 ]; then
        echo "Error executing:./Configure ${architecture}"
        exit 1
    fi

    echo "make clean"
    make clean
    echo "make"
    make

    if [ $? -ne 0 ]; then
        echo "Error executing: make ${architecture}"
        exit 1
    fi

    OUTPUT_INCLUDE=$SCRIPTPATH/include
    OUTPUT_LIB=${ANDROID_LIB_ROOT}/${TARGET_PLATFORM}
    mkdir -p $OUTPUT_INCLUDE
    mkdir -p $OUTPUT_LIB
    cp -RL include/openssl $OUTPUT_INCLUDE
    cp libcrypto.so $OUTPUT_LIB
    cp libcrypto.a $OUTPUT_LIB
    cp libssl.so $OUTPUT_LIB
    cp libssl.a $OUTPUT_LIB

    echo "Done Building OpenSSL for ${architecture}"
done
