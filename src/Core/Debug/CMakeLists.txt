target_include_directories(oolite
        PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}
)

target_sources(oolite
        PRIVATE
        OODebugMonitor.m
        OODebugStandards.m
        OODebugSupport.m
        OODebugTCPConsoleClient.m
        OOJSConsole.m
        OOTCPStreamDecoderAbstractionLayer.m
        OOTCPStreamDecoder.c
)
