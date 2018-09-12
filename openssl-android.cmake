cmake_minimum_required(VERSION 3.4.1)

link_directories(/Users/paulshields/Projects/openssl-mobile/lib/android/${ANDROID_ABI})
include_directories(/Users/paulshields/Projects/openssl-mobile/include)

set(OpenSSL ssl crypto)
