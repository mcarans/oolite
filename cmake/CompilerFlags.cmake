if (APPLE)
else ()
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