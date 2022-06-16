#!/bin/bash

buildiOS() {
  scripts/build-library.sh ios-armv8
  scripts/build-library.sh iossimulator-armv8
  scripts/build-library.sh iossimulator-x86

  mkdir lib/iossimulator
  lipo \
   	lib/iossimulator-armv8/libcrypto.a \
   	lib/iossimulator-x86/libcrypto.a \
   	-create -output lib/iossimulator/libcrypto.a \

  xcodebuild -create-xcframework \
    -library lib/ios-armv8/libcrypto.a \
    -library lib/iossimulator/libcrypto.a \
  	-output lib/ios/libcrypto.xcframework

  lipo \
    lib/iossimulator-armv8/libssl.a \
    lib/iossimulator-x86/libssl.a \
    -create -output lib/iossimulator/libssl.a \

  xcodebuild -create-xcframework \
    -library lib/ios-armv8/libssl.a \
    -library lib/iossimulator/libssl.a \
  	-output lib/ios/libssl.xcframework

  rm -r lib/ios-armv8 lib/iossimulator-armv8 lib/iossimulator-x86 lib/iossimulator
}

buildAndroid() {
  scripts/build-library.sh android-armv8 android/arm64-v8a
  scripts/build-library.sh android-armv7 android/armeabi-v7a
  scripts/build-library.sh android-x86_64 android/x86_64
  scripts/build-library.sh android-x86 android/x86
}

buildMacOS() {
  scripts/build-library.sh macos-armv8 macos/armv8
  scripts/build-library.sh macos-x86 macos/x86

  lipo \
    lib/macos/armv8/libcrypto.a \
    lib/macos/x86/libcrypto.a \
    -create -output lib/macos/libcrypto.a

  rm -rf lib/macos/armv8 lib/macos/x86
}

buildLinux() {
  buildLinuxDockerImage
  buildLinuxLibraries linux-armv8 linux/armv8
  buildLinuxLibraries linux-x86 linux/x86
}

buildLinuxDockerImage() {
  docker build --force-rm --no-cache -f linux-dockerfile -t openssl .
}

buildLinuxLibraries() {
  mkdir -p lib/$2
  docker run --name openssl openssl /openssl-mobile/scripts/build-library.sh $1 $2
  docker cp openssl:/openssl-mobile/lib/$2/. lib/$2
  docker rm openssl
}

set -e
cd "$(dirname "$0")"

rm -rf lib include

buildiOS
buildAndroid
buildMacOS
buildLinux

if [[ $1 == "--package" ]]; then
  zip -r package.zip include lib
  echo "Package has been created at $(pwd)/package.zip"
fi
