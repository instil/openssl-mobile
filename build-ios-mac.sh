#!/bin/bash

# This script builds the iOS and Mac OpenSSL libraries with Bitcode enabled

# Credits:
# https://gist.github.com/dgventura/812a0e02bdccf08f2866fb08bb39f4be

# Updated to work with Xcode 8.3.3 and iOS 10.10.

set -e

###################################
# 		 SDK Version
###################################
IOS_SDK_VERSION=$(xcodebuild -version -sdk iphoneos | grep SDKVersion | cut -f2 -d ':' | tr -d '[[:space:]]')
###################################

################################################
# 		 Minimum iOS deployment target version
################################################
MIN_IOS_VERSION="9.0"

################################################
# 		 Minimum OS X deployment target version
################################################
MIN_OSX_VERSION="10.10"

################################################
# 		 Xcode developer directory
################################################
XCODE_DEV_PATH=`xcode-select -print-path`

################################################
# 		 Temp directory to build OpenSSL into
################################################
TEMP_BASE_DIR="/tmp/openssl"


echo "----------------------------------------"
echo "Building OpenSSL for iOS and Mac"
echo " "
echo "iOS SDK version: ${IOS_SDK_VERSION}"
echo "iOS deployment target: ${MIN_IOS_VERSION}"
echo "OS X deployment target: ${MIN_OSX_VERSION}"
echo "----------------------------------------"
echo " "


buildMac()
{
	ARCH=$1

	echo "Start Building OpenSSL for ${ARCH}"
	TARGET="darwin-i386-cc"
	if [[ $ARCH == "x86_64" ]]; then
		TARGET="darwin64-x86_64-cc"
	fi
	
	export CC="${BUILD_TOOLS}/usr/bin/clang -mmacosx-version-min=${MIN_OSX_VERSION}"
	
	pushd . > /dev/null
	
	cd "openssl"
	echo "Configure"
	./Configure ${TARGET} --openssldir="${TEMP_BASE_DIR}/${ARCH}" --prefix="${TEMP_BASE_DIR}/${ARCH}" &> "${TEMP_BASE_DIR}/${ARCH}.log"
	make >> "${TEMP_BASE_DIR}/${ARCH}.log" 2>&1
	
	echo "make install"
	make install_sw >> "${TEMP_BASE_DIR}/${ARCH}.log" 2>&1
	
	echo "make clean"
	make clean >> "${TEMP_BASE_DIR}/${ARCH}.log" 2>&1
	
	popd > /dev/null
	
	echo "Done Building OpenSSL for ${ARCH}"
}
buildIOS()
{
	ARCH=$1
	
	pushd . > /dev/null
	cd "openssl"
  
	if [[ "${ARCH}" == "i386" || "${ARCH}" == "x86_64" ]]; then
		PLATFORM="iPhoneSimulator"
	else
		PLATFORM="iPhoneOS"
		sed -ie "s!static volatile sig_atomic_t intr_signal;!static volatile intr_signal;!" "crypto/ui/ui_openssl.c"
	fi

	export $PLATFORM	
	echo "Start Building OpenSSL for ${PLATFORM} ${IOS_SDK_VERSION} ${ARCH}"
  
	export CROSS_TOP="${XCODE_DEV_PATH}/Platforms/${PLATFORM}.platform/Developer"
	export CROSS_SDK="${PLATFORM}${IOS_SDK_VERSION}.sdk"
	export BUILD_TOOLS="${XCODE_DEV_PATH}"
	export CC="${BUILD_TOOLS}/usr/bin/gcc -fembed-bitcode -mios-version-min=${MIN_IOS_VERSION} -arch ${ARCH}"
	
	echo "Configure"
	./Configure iphoneos-cross -no-engine --openssldir="${TEMP_BASE_DIR}/iOS-${ARCH}" --prefix="${TEMP_BASE_DIR}/iOS-${ARCH}" &> "${TEMP_BASE_DIR}/iOS-${ARCH}.log"
	sed -ie "s!^CFLAG=!CFLAG=-isysroot ${CROSS_TOP}/SDKs/${CROSS_SDK} -mios-version-min=${MIN_IOS_VERSION} !" "Makefile"
	sed -ie 's/\/usr\/bin\/gcc/\/Toolchains\/XcodeDefault.xctoolchain\/usr\/bin\/clang/g' Makefile
	
	echo "make"
	make >> "${TEMP_BASE_DIR}/iOS-${ARCH}.log" 2>&1
	
	echo "make install"
	make install_sw >> "${TEMP_BASE_DIR}/iOS-${ARCH}.log" 2>&1
	
	echo "make clean"
	make clean  >> "${TEMP_BASE_DIR}/iOS-${ARCH}.log" 2>&1
	
	popd > /dev/null
	
	echo "Done Building OpenSSL for ${ARCH}"
}

echo "Cleaning up"
rm -rf include/openssl/* lib/*
rm -rf ${TEMP_BASE_DIR}
mkdir -p lib/ios
mkdir -p lib/mac
mkdir -p include/openssl/
mkdir -p ${TEMP_BASE_DIR}

buildMac "i386"
buildMac "x86_64"
echo "Building Mac libraries"
lipo \
	"${TEMP_BASE_DIR}/i386/lib/libcrypto.a" \
	"${TEMP_BASE_DIR}/x86_64/lib/libcrypto.a" \
	-create -output lib/mac/libcrypto.a
lipo \
	"${TEMP_BASE_DIR}/i386/lib/libssl.a" \
	"${TEMP_BASE_DIR}/x86_64/lib/libssl.a" \
	-create -output lib/mac/libssl.a


buildIOS "x86_64"
buildIOS "i386"
buildIOS "armv7"
buildIOS "arm64"
echo "Building iOS libraries"
lipo \
	"${TEMP_BASE_DIR}/iOS-armv7/lib/libcrypto.a" \
	"${TEMP_BASE_DIR}/iOS-arm64/lib/libcrypto.a" \
	"${TEMP_BASE_DIR}/iOS-i386/lib/libcrypto.a" \
	"${TEMP_BASE_DIR}/iOS-x86_64/lib/libcrypto.a" \
	-create -output lib/ios/libcrypto.a
lipo \
	"${TEMP_BASE_DIR}/iOS-armv7/lib/libssl.a" \
	"${TEMP_BASE_DIR}/iOS-arm64/lib/libssl.a" \
	"${TEMP_BASE_DIR}/iOS-i386/lib/libssl.a" \
	"${TEMP_BASE_DIR}/iOS-x86_64/lib/libssl.a" \
	-create -output lib/ios/libssl.a

echo "Copying headers"
cp ${TEMP_BASE_DIR}/i386/include/openssl/* include/openssl/

echo "Cleaning up"
rm -rf ${TEMP_BASE_DIR}/*
echo "Done"
