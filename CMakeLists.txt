cmake_minimum_required(VERSION 3.31)
project(oolite)

set(CMAKE_C_STANDARD 98)
set(CMAKE_CXX_STANDARD 98)


enable_language(C CXX OBJC)
#add_compile_definitions(WITH_COCOA)
#add_compile_options($<$<COMPILE_LANGUAGE:OBJC,OBJCXX>:-fobjc-abi-version=1>)


list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

if (APPLE)
    set(CMAKE_FIND_FRAMEWORK ONLY)
    find_library(Cocoa_LIBRARIES Foundation REQUIRED)
else ()
    find_package(GNUstep REQUIRED COMPONENTS Base)
endif ()

find_package(OpenGL)
find_package(OpenAL)
find_package(SDL)
find_package(ZLIB)
find_package(PNG)
find_package(X11)
find_package(NSPR)
find_package(Vorbis)

add_executable(oolite)

target_include_directories(oolite
        PRIVATE
        X11_INCLUDE_DIR
        NSPR_INCLUDE_DIRS
        VORBIS_INCLUDE_DIR
        ${CMAKE_CURRENT_SOURCE_DIR}/deps/Linux-deps/x86_64/mozilla/include
        ${CMAKE_CURRENT_SOURCE_DIR}/deps/Linux-deps/include
)

target_link_libraries(oolite
        PRIVATE
        OpenGL::GL
        OpenGL::GLU
        OpenAL::OpenAL
        SDL::SDL
        ZLIB:ZLIB
        PNG::PNG
        X11_LIBRARIES
        NSPR_LIBRARIES
        VORBISFILE_LIBRARY
        ${CMAKE_CURRENT_SOURCE_DIR}/deps/Linux-deps/x86_64/mozilla/js_static
)

add_subdirectory(src)

