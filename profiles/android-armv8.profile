include(default)

[settings]
os=Android
os.api_level=21
arch=armv8
compiler=gcc
compiler.libcxx=libstdc++11
compiler.version=9

[build_requires]
*: android-ndk/r22
