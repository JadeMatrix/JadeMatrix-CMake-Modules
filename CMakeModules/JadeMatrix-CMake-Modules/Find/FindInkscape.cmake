IF( NOT TARGET Inkscape )
    IF( APPLE )
        # CMake wants to prefer Inkscape.app/Contents/MacOS/Inkscape, which
        # didn't work on macOS prior to Inkscape 1.0 -- need to use
        # Inkscape.app/Contents/Resources/bin/inkscape
        FIND_PROGRAM(
            INKSCAPE_LOCATION
            inkscape
            PATHS
                "$ENV{HOME}/Applications/Inkscape.app/Contents/Resources/bin"
                "/Applications/Inkscape.app/Contents/Resources/bin"
            NO_DEFAULT_PATH
        )
    ENDIF()

    IF( NOT INKSCAPE_LOCATION )
        FIND_PROGRAM( INKSCAPE_LOCATION inkscape )
    ENDIF ()

    IF( INKSCAPE_LOCATION )
        EXECUTE_PROCESS(
            COMMAND "${INKSCAPE_LOCATION}" --version
            RESULT_VARIABLE INKSCAPE_VERSION_RESULT
            OUTPUT_VARIABLE INKSCAPE_VERSION_RAW
            ERROR_QUIET
        )
        IF( INKSCAPE_VERSION_RESULT EQUAL 0 )
            STRING( REGEX MATCH
                "[0-9]+\\.[0-9]+(\\.[0-9]+)*"
                Inkscape_VERSION
                "${INKSCAPE_VERSION_RAW}"
            )
            ADD_EXECUTABLE( Inkscape IMPORTED )
            SET_TARGET_PROPERTIES( Inkscape PROPERTIES
                IMPORTED_LOCATION "${INKSCAPE_LOCATION}"
                VERSION "${Inkscape_VERSION}"
            )
        ENDIF ()
    ENDIF()

    INCLUDE( FindPackageHandleStandardArgs )
    FIND_PACKAGE_HANDLE_STANDARD_ARGS(
        Inkscape
        FOUND_VAR Inkscape_FOUND
        REQUIRED_VARS INKSCAPE_LOCATION Inkscape_VERSION
        VERSION_VAR Inkscape_VERSION
    )
ENDIF()
