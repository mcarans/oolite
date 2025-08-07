if (APPLE)
else ()
    IF(MINGW)
        set(OS_INCLUDE Windows-deps/x86_64/include)
        set(JS_INCLUDE Windows-deps/x86_64/JS32ECMAv5/include)
        set(JS_LIBRARY Windows-deps/x86_64/JS32ECMAv5/js32ECMAv5)
    else ()
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

