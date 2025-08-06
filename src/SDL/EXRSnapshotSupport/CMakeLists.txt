target_sources(oolite
        PRIVATE
        OOSaveEXRSnapshot.cpp
)

# Only for Windows currently
if (MINGW)
    target_sources(oolite
            PRIVATE
            miniz.c
    )
endif ()