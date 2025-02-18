# the minimum version of CMake.
cmake_minimum_required(VERSION 3.5.0)
project(MyApplication2)

set(NATIVERENDER_ROOT_PATH types)

if(DEFINED PACKAGE_FIND_FILE)
    include(${PACKAGE_FIND_FILE})
endif()

include_directories(${NATIVERENDER_ROOT_PATH}
                    ${NATIVERENDER_ROOT_PATH}/include)
