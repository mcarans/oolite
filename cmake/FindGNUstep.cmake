# Taken from https://git.dblsaiko.net/nucom/tree/cmake/FindGNUstep.cmake?h=rt
# Added PATH_SUFFIXES GNUstep

include(CMakeParseArguments)
include(FindPackageHandleStandardArgs)

set(_gnustep_not_found_message)

if (NOT GNUstep_FIND_COMPONENTS)
    # FIXME: there's gotta be a better way to do this
    # unfortunately find modules don't work at all like config modules
    set(_gnustep_force_error)
    find_package_handle_standard_args(GNUstep
            REQUIRED_VARS _gnustep_force_error
            REASON_FAILURE_MESSAGE "The GNUstep package requires at least one component")
endif ()

set(_gnustep_want_objc NO)
set(_gnustep_want_base NO)
set(_gnustep_want_gui NO)

foreach (_gnustep_item ${GNUstep_FIND_COMPONENTS})
    if (_gnustep_item STREQUAL ObjC)
        set(_gnustep_want_objc YES)
    elseif (_gnustep_item STREQUAL Base)
        set(_gnustep_want_base YES)
    elseif (_gnustep_item STREQUAL Gui)
        set(_gnustep_want_gui YES)
    else ()
        set(_gnustep_msg "Invalid GNUstep component \"${_gnustep_item}\"\n")

        if (GNUstep_FIND_REQUIRED_${_gnustep_item})
            list(APPEND _gnustep_not_found_message "${_gnustep_msg}")
        elseif (NOT GNUstep_FIND_QUIETLY)
            message(WARNING "${_gnustep_msg}")
        endif ()
    endif ()
endforeach ()

if (_gnustep_want_gui)
    set(_gnustep_want_base YES)
endif ()

if (_gnustep_want_base)
    set(_gnustep_want_objc YES)
endif ()

# Actually search

function(_gnustep_get_flags_from_config target)
    set(options APPEND)
    set(one_value_args CONFIG_FLAG)
    set(multi_value_args)
    cmake_parse_arguments(ARGS "${options}" "${one_value_args}" "${multi_value_args}" ${ARGN})

    execute_process(
            COMMAND ${GNUstep_GNUSTEP_CONFIG_EXECUTABLE} "${ARGS_CONFIG_FLAG}"
            OUTPUT_VARIABLE _gnustep_output
            COMMAND_ERROR_IS_FATAL ANY
            OUTPUT_STRIP_TRAILING_WHITESPACE)

    string(REPLACE " " ";" _gnustep_output "${_gnustep_output}")

    foreach (_gnustep_item ${_gnustep_output})
        if (_gnustep_item MATCHES ^-D)
            target_compile_definitions("${target}" INTERFACE
                    $<$<COMPILE_LANGUAGE:OBJC,OBJCXX>:${_gnustep_item}>)
        elseif (_gnustep_item MATCHES ^-f)
            target_compile_options("${target}" INTERFACE
                    $<$<COMPILE_LANGUAGE:OBJC,OBJCXX>:${_gnustep_item}>)
        elseif (_gnustep_item STREQUAL -pthread)
            find_package(Threads REQUIRED)
            target_link_libraries("${target}" INTERFACE
                    Threads::Threads)
        elseif (_gnustep_item MATCHES ^-[OWg])
            # don't do anything with these
        else ()
            message(DEBUG "unhandled flag: ${_gnustep_item}")
        endif ()
    endforeach ()
endfunction()

find_program(GNUstep_GNUSTEP_CONFIG_EXECUTABLE gnustep-config REQUIRED)

if (_gnustep_want_objc)
    # This actually comes with a .pc file so we wouldn't necessarily need this

    find_path(GNUstep_ObjC_INCLUDE_DIR
            NAMES
            objc/objc.h
            REQUIRED
            PATH_SUFFIXES
            GNUstep)

    find_library(GNUstep_ObjC_LIBRARY objc REQUIRED)

    add_library(GNUstep::ObjC UNKNOWN IMPORTED)
    set_target_properties(GNUstep::ObjC PROPERTIES
            IMPORTED_LOCATION "${GNUstep_ObjC_LIBRARY}")
    target_include_directories(GNUstep::ObjC INTERFACE
            $<$<COMPILE_LANGUAGE:OBJC,OBJCXX>:${_gnustep_headers}>)

    _gnustep_get_flags_from_config(GNUstep::ObjC CONFIG_FLAG --objc-flags)
    _gnustep_get_flags_from_config(GNUstep::ObjC CONFIG_FLAG --objc-libs)

    set(GNUstep_ObjC_FOUND YES)
endif ()

if (_gnustep_want_base)
    find_path(_gnustep_headers
            NAMES
            Foundation/Foundation.h
            GNUstepBase/GNUstep.h
            REQUIRED
            PATH_SUFFIXES
            GNUstep)

    find_library(GNUstep_Base_LIBRARY gnustep-base REQUIRED)

    add_library(GNUstep::Base UNKNOWN IMPORTED)
    set_target_properties(GNUstep::Base PROPERTIES
            IMPORTED_LOCATION "${GNUstep_Base_LIBRARY}")
    target_link_libraries(GNUstep::Base INTERFACE GNUstep::ObjC)
    target_include_directories(GNUstep::Base INTERFACE
            $<$<COMPILE_LANGUAGE:OBJC,OBJCXX>:${_gnustep_headers}>)

    _gnustep_get_flags_from_config(GNUstep::Base CONFIG_FLAG --base-libs)

    set(GNUstep_Base_FOUND YES)
endif ()

if (_gnustep_want_gui)
    find_path(_gnustep_headers
            NAMES
            GNUstepGUI/GSVersion.h
            REQUIRED
            PATH_SUFFIXES
            GNUstep)

    find_library(GNUstep_Gui_LIBRARY gnustep-gui REQUIRED)

    add_library(GNUstep::Gui UNKNOWN IMPORTED)
    set_target_properties(GNUstep::Gui PROPERTIES
            IMPORTED_LOCATION "${GNUstep_Gui_LIBRARY}")
    target_link_libraries(GNUstep::Gui INTERFACE GNUstep::ObjC GNUstep::Base)
    target_include_directories(GNUstep::Gui INTERFACE
            $<$<COMPILE_LANGUAGE:OBJC,OBJCXX>:${_gnustep_headers}>)

    _gnustep_get_flags_from_config(GNUstep::Gui CONFIG_FLAG --gui-libs)

    set(GNUstep_Gui_FOUND YES)
endif ()

find_package_handle_standard_args(GNUstep
        HANDLE_COMPONENTS
        REASON_FAILURE_MESSAGE ${_gnustep_not_found_message})

include(FeatureSummary)
set_package_properties(GNUstep PROPERTIES
        URL "https://gnustep.org"
        DESCRIPTION "The GNUstep Framework")
