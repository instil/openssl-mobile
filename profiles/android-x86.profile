include(default)

[settings]
os=Android
os.api_level=21
arch=x86
compiler=gcc
compiler.libcxx=libstdc++11
compiler.version=9

[build_requires]
*: android-ndk/r24
