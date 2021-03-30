#!/bin/bash

# This script builds the iOS and Mac OpenSSL libraries with Bitcode enabled

# Credits:
# https://gist.github.com/dgventura/812a0e02bdccf08f2866fb08bb39f4be

set -e

MIN_IOS_VERSION="10.0"
MIN_OSX_VERSION="10.10"
IOS_SDK_VERSION=$(xcodebuild -version -sdk iphoneos | grep SDKVersion | cut -f2 -d ':' | tr -d '[[:space:]]')
XCODE_DEV_PATH=`xcode-select -print-path`
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
	LOG_FILE="${TEMP_BASE_DIR}/${ARCH}.log"

	echo "Start Building OpenSSL for ${ARCH}"
	echo ">> Logs available at ${LOG_FILE}"

	TARGET="darwin64-${ARCH}-cc"

	export CC="${BUILD_TOOLS}/usr/bin/clang -mmacosx-version-min=${MIN_OSX_VERSION}"

	pushd . > /dev/null

	cd "openssl"

	echo "make clean"
	make clean >> $LOG_FILE 2>&1

	echo "Configure"
	./Configure ${TARGET} --openssldir="${TEMP_BASE_DIR}/${ARCH}" --prefix="${TEMP_BASE_DIR}/${ARCH}" &> $LOG_FILE
	make >> $LOG_FILE 2>&1

	echo "make install"
	make install_sw >> $LOG_FILE 2>&1

	echo "make clean"
	make clean >> $LOG_FILE 2>&1

	popd > /dev/null

	echo "Done Building OpenSSL for ${ARCH}"
	echo " "
}
buildIOS()
{
	ARCH=$1
	PLATFORM=$2
	LOG_FILE="${TEMP_BASE_DIR}/iOS-${ARCH}-${PLATFORM}.log"

	pushd . > /dev/null
	cd "openssl"

	if [[ "${PLATFORM}" == "iPhoneOS" ]]; then
		sed -ie "s!static volatile sig_atomic_t intr_signal;!static volatile intr_signal;!" "crypto/ui/ui_openssl.c"
	fi

	export $PLATFORM
	echo "Start Building OpenSSL for ${PLATFORM} ${IOS_SDK_VERSION} ${ARCH}"
	echo ">> Logs available at ${LOG_FILE}"

	export CROSS_TOP="${XCODE_DEV_PATH}/Platforms/${PLATFORM}.platform/Developer"
	export CROSS_SDK="${PLATFORM}${IOS_SDK_VERSION}.sdk"
	export BUILD_TOOLS="${XCODE_DEV_PATH}"
	export CC="${BUILD_TOOLS}/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang -arch ${ARCH} -fembed-bitcode"

	echo "Configure"
	./Configure iphoneos-cross -no-engine -no-async --openssldir="${TEMP_BASE_DIR}/iOS-${ARCH}-${PLATFORM}" --prefix="${TEMP_BASE_DIR}/iOS-${ARCH}-${PLATFORM}" &> $LOG_FILE

	if [[ "${PLATFORM}" == "iPhoneOS" ]]; then
		sed -ie "s!^CFLAGS=!CFLAGS=-isysroot ${CROSS_TOP}/SDKs/${CROSS_SDK} -mios-version-min=${MIN_IOS_VERSION} !" "Makefile"
		sed -ie 's/\/usr\/bin\/gcc/\/Toolchains\/XcodeDefault.xctoolchain\/usr\/bin\/clang/g' Makefile
	fi

	echo "make"
	make >> $LOG_FILE 2>&1

	echo "make install"
	make install_sw >> $LOG_FILE 2>&1

	echo "make clean"
	make clean  >> $LOG_FILE 2>&1

	popd > /dev/null

	echo "Done Building OpenSSL for ${ARCH}"
	echo " "
}

echo "Cleaning up"
rm -rf include/openssl/* lib/*
rm -rf ${TEMP_BASE_DIR}
mkdir -p lib/ios
mkdir -p lib/mac
mkdir -p include/openssl/
mkdir -p ${TEMP_BASE_DIR}

echo "Building Mac libraries"
buildMac "x86_64"
buildMac "arm64"
lipo \
 	"${TEMP_BASE_DIR}/x86_64/lib/libcrypto.a" \
 	"${TEMP_BASE_DIR}/arm64/lib/libcrypto.a" \
 	-create -output lib/mac/libcrypto.a
lipo \
 	"${TEMP_BASE_DIR}/x86_64/lib/libssl.a" \
 	"${TEMP_BASE_DIR}/arm64/lib/libssl.a" \
 	-create -output lib/mac/libssl.a

echo "Building iOS libraries"
buildIOS "x86_64" "iPhoneSimulator"
buildIOS "i386" "iPhoneSimulator"
buildIOS "arm64" "iPhoneSimulator"
buildIOS "armv7" "iPhoneOS"
buildIOS "arm64" "iPhoneOS"

mkdir ${TEMP_BASE_DIR}/iphoneos
mkdir ${TEMP_BASE_DIR}/iphonesimulator

lipo \
 	"${TEMP_BASE_DIR}/iOS-armv7-iPhoneOS/lib/libcrypto.a" \
 	"${TEMP_BASE_DIR}/iOS-arm64-iPhoneOS/lib/libcrypto.a" \
 	-create -output ${TEMP_BASE_DIR}/iphoneos/libcrypto.a

lipo \
 	"/tmp/openssl/iOS-arm64-iPhoneSimulator/lib/libcrypto.a" \
 	"/tmp/openssl/iOS-i386-iPhoneSimulator/lib/libcrypto.a" \
 	"/tmp/openssl/iOS-x86_64-iPhoneSimulator/lib/libcrypto.a" \
 	-create -output ${TEMP_BASE_DIR}/iphonesimulator/libcrypto.a

xcodebuild -create-xcframework \
	-library ${TEMP_BASE_DIR}/iphonesimulator/libcrypto.a \
	-library ${TEMP_BASE_DIR}/iphoneos/libcrypto.a \
	-output lib/ios/libcrypto.xcframework

lipo \
 	"/tmp/openssl/iOS-armv7-iPhoneOS/lib/libssl.a" \
 	"/tmp/openssl/iOS-arm64-iPhoneOS/lib/libssl.a" \
 	-create -output ${TEMP_BASE_DIR}/iphoneos/libssl.a

lipo \
 	"/tmp/openssl/iOS-arm64-iPhoneSimulator/lib/libssl.a" \
 	"/tmp/openssl/iOS-i386-iPhoneSimulator/lib/libssl.a" \
 	"/tmp/openssl/iOS-x86_64-iPhoneSimulator/lib/libssl.a" \
 	-create -output ${TEMP_BASE_DIR}/iphonesimulator/libssl.a

xcodebuild -create-xcframework \
	-library ${TEMP_BASE_DIR}/iphonesimulator/libssl.a \
	-library ${TEMP_BASE_DIR}/iphoneos/libssl.a \
	-output lib/ios/libssl.xcframework

echo "Copying headers"
cp ${TEMP_BASE_DIR}/x86_64/include/openssl/* include/openssl/

echo "Cleaning up"
rm -rf ${TEMP_BASE_DIR}/*
echo "Done"
