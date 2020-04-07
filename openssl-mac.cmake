cmake_minimum_required(VERSION 3.4.1)

link_directories(${CMAKE_CURRENT_LIST_DIR}/lib/mac)
include_directories(${CMAKE_CURRENT_LIST_DIR}/include)

set(OpenSSL ssl crypto)
