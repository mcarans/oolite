cmake_minimum_required(VERSION 3.31)
project(oolite)

set(CMAKE_C_STANDARD 99)
set(CMAKE_CXX_STANDARD 98)
enable_language(C CXX OBJC)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

set(OpenGL_GL_PREFERENCE LEGACY)
find_package(OpenGL REQUIRED COMPONENTS OpenGL)
find_package(OpenAL)
find_package(SDL)
find_package(ZLIB)
find_package(PNG)
find_package(X11)
find_package(NSPR)
find_package(Vorbis)

if (APPLE)
    set(CMAKE_FIND_FRAMEWORK ONLY)
    find_library(Cocoa_LIBRARIES Foundation REQUIRED)
else ()
    find_package(GNUstep REQUIRED COMPONENTS Base)
endif ()

add_executable(oolite)

include(CompilerFlags)
include(IncludesLinks)

add_subdirectory(src)

