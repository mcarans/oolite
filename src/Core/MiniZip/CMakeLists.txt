target_include_directories(oolite
        PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}
)

target_sources(oolite
        PRIVATE
        ioapi.c
        unzip.c
)