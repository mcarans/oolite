cmake_minimum_required(VERSION 3.31)
project(oolite)

set(CMAKE_C_STANDARD 99)
set(CMAKE_CXX_STANDARD 98)
enable_language(C CXX OBJC)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

add_executable(oolite)

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
        set(OS_INCLUDE Windows-deps/x86_64/include)
        set(JS_INCLUDE Windows-deps/x86_64/JS32ECMAv5/include)
        set(JS_LIBRARY Windows-deps/x86_64/JS32ECMAv5/js32ECMAv5)
    else ()
        target_compile_definitions(oolite
                PRIVATE
                LINUX
                $<$<COMPILE_LANGUAGE:OBJC,OBJCXX>:XP_UNIX>)
        set(OS_INCLUDE Linux-deps/include)
        set(JS_INCLUDE Linux-deps/x86_64/mozilla/include)
        set(JS_LIBRARY Linux-deps/x86_64/mozilla/libjs_static.a)
    endif ()
endif ()

target_include_directories(oolite
        PRIVATE
        ${OPENGL_INCLUDE_DIR}
        ${CMAKE_CURRENT_SOURCE_DIR}/deps/${OS_INCLUDE}
        ${CMAKE_CURRENT_SOURCE_DIR}/deps/${JS_INCLUDE}
)

target_link_libraries(oolite
        PRIVATE
        GNUstep::ObjC
        GNUstep::Base
        OpenGL::GL
        OpenGL::GLU
        OpenAL::OpenAL
        SDL::SDL
        PNG::PNG
        ${ZLIB_LIBRARIES}
        ${X11_LIBRARIES}
        ${NSPR_LIBRARIES}
        ${VORBISFILE_LIBRARY}
        ${CMAKE_CURRENT_SOURCE_DIR}/deps/${JS_LIBRARY}
)

add_subdirectory(src)

