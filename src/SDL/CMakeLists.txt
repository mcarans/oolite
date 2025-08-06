target_include_directories(oolite PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})

target_sources(oolite
        PRIVATE
        Comparison.m
        GameController+SDLFullScreen.m
        main.m
        MyOpenGLView.m
        OOSDLJoystickManager.m
)

add_subdirectory(EXRSnapshotSupport)
if (MINGW)
    add_subdirectory(OOResourceWin)
endif ()
