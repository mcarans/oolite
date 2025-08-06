cmake_minimum_required(VERSION 3.31)
project(oolite)

set(CMAKE_C_STANDARD 99)
set(CMAKE_CXX_STANDARD 98)


enable_language(C CXX OBJC)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

add_executable(oolite)

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
    target_compile_definitions(oolite
            PRIVATE
            $<$<COMPILE_LANGUAGE:C>:GNUSTEP>)
    if(CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
        target_compile_options(oolite
                PRIVATE
                $<$<COMPILE_LANGUAGE:OBJC,OBJCXX>:-fobjc-runtime=gnustep-1.9>)
    endif ()
    IF(MINGW)
        target_compile_definitions(oolite
                PRIVATE
                WIN32
                $<$<COMPILE_LANGUAGE:OBJC,OBJCXX>:XP_WIN>)
    else ()
        target_compile_definitions(oolite
                PRIVATE
                LINUX
                $<$<COMPILE_LANGUAGE:OBJC,OBJCXX>:XP_UNIX>)
    endif ()
endif ()

target_include_directories(oolite
        PRIVATE
        ${OPENGL_INCLUDE_DIR}
        ${CMAKE_CURRENT_SOURCE_DIR}/deps/Linux-deps/x86_64/mozilla/include
        ${CMAKE_CURRENT_SOURCE_DIR}/deps/Linux-deps/include
)

target_link_libraries(oolite
        PRIVATE
        GL
        GLU
        GNUstep::ObjC
        GNUstep::Base
        OpenAL::OpenAL
        SDL::SDL
        PNG::PNG
        ${ZLIB_LIBRARIES}
        ${X11_LIBRARIES}
        ${NSPR_LIBRARIES}
        ${VORBISFILE_LIBRARY}
        ${CMAKE_CURRENT_SOURCE_DIR}/deps/Linux-deps/x86_64/mozilla/libjs_static.a
)

add_subdirectory(src)

