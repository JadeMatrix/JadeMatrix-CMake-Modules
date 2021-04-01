#[=======================================================================[.rst:
JadeMatrix-CMake-Modules/Util/Inkscape
--------------------------------------

This module provides utilities for working with Inkscape from CMake.

.. command:: ADD_INKSCAPE_BITMAP
    
    ADD_INKSCAPE_BITMAP(
        <svg-file>
        <output-file>
        [ EXPORT <export-spec> ]
        [ DPI <dpi> ]
        [ TARGET <target-name> ]
        [ OUTPUT_DIR <output-dir> ]
        [ DEPENDS <target-name>... ]
        [ DEPENDEES <target-name>... ]
        [ CREATE_INSTALL_RULE ]
    )
    
    Configure a bitmap image ``<output-file>`` to be generated from an SVG
    ``<svg-file>`` as part of the build process.
    
    The options are:
    
    ``EXPORT <export-spec>``
        Either ``page``, ``drawing``, or an area in SVG user units in the form
        ``x0:y0:x1:y1``; defaults to ``page``.
    
    ``DPI <dpi>``
        Export DPI; defaults to 96.
    
    ``TARGET <target-name>``
        Define a custom target name for the export step.  Defaults to a name
        generated from ``<output-file>``.
    
    ``OUTPUT_DIR <output-dir>``
        Manually specify the output directory part of of ``<output-file>`` in
        case the generated command fails to parse the path properly.
    
    ``DEPENDS <target-name>...``
        Targets on which the export process for this bitmap depends.
    
    ``DEPENDEES <target-name>...``
        Targets which depend on the export process for this bitmap.  This is
        typically only useful if no ``TARGET`` is specified, as the generated
        bitmap target name won't be available for passing to
        ``ADD_DEPENDENCIES()``.
    
    ``CREATE_INSTALL_RULE``
        Create an install rule for the exported bitmap, installing it verbatim
        as ``<output-file>``.
#]=======================================================================]

CMAKE_MINIMUM_REQUIRED( VERSION 3.5 FATAL_ERROR #[[
    Requiring 3.5+:
        CMAKE_PARSE_ARGUMENTS( ... )
]] )

FIND_PACKAGE( Inkscape 1 REQUIRED )

FUNCTION( ADD_INKSCAPE_BITMAP SVG_FILE OUTPUT_FILE )
    CMAKE_PARSE_ARGUMENTS(
        "ADD_INKSCAPE_BITMAP"
        "CREATE_INSTALL_RULE"
        "EXPORT;DPI;TARGET;OUTPUT_DIR"
        "DEPENDS;DEPENDEES"
        ${ARGN}
    )
    
    IF( IS_ABSOLUTE OUTPUT_FILE )
        FILE( RELATIVE_PATH OUTPUT_FILE
            "${CMAKE_CURRENT_BINARY_DIR}"
            "${OUTPUT_FILE}"
        )
    ENDIF()
    
    IF( NOT DEFINED ADD_INKSCAPE_BITMAP_EXPORT )
        SET( ADD_INKSCAPE_BITMAP_EXPORT "page" )
    ENDIF()
    
    IF( ADD_INKSCAPE_BITMAP_EXPORT STREQUAL "page" )
        SET( EXPORT_ARG "--export-area-page" )
    ELSEIF( ADD_INKSCAPE_BITMAP_EXPORT STREQUAL "drawing" )
        SET( EXPORT_ARG "--export-area-drawing" )
    ELSE()
        SET( EXPORT_ARG "--export-area=${ADD_INKSCAPE_BITMAP_EXPORT}" )
    ENDIF()
    
    IF( NOT DEFINED ADD_INKSCAPE_BITMAP_DPI )
        SET( ADD_INKSCAPE_BITMAP_DPI "96" )
    ENDIF()
    
    IF( NOT DEFINED ADD_INKSCAPE_BITMAP_TARGET )
        STRING( REGEX REPLACE "[/ \t\n\r&<>\"']" "_" ADD_INKSCAPE_BITMAP_TARGET
            "${OUTPUT_FILE}"
        )
    ENDIF()
    
    # This fails on some paths on some operating systems, so only compute it if
    # not given
    IF( NOT DEFINED ADD_INKSCAPE_BITMAP_OUTPUT_DIR )
        GET_FILENAME_COMPONENT(
            ADD_INKSCAPE_BITMAP_OUTPUT_DIR
            "${OUTPUT_FILE}"
            DIRECTORY
        )
    ENDIF()
    
    ADD_CUSTOM_COMMAND(
        VERBATIM
        COMMAND "${CMAKE_COMMAND}"
            -E make_directory "${CMAKE_CURRENT_BINARY_DIR}/${ADD_INKSCAPE_BITMAP_OUTPUT_DIR}"
        COMMAND Inkscape
            "--export-filename=${CMAKE_CURRENT_BINARY_DIR}/${OUTPUT_FILE}"
            "--export-dpi=${ADD_INKSCAPE_BITMAP_DPI}"
            "${EXPORT_ARG}"
            "${CMAKE_CURRENT_SOURCE_DIR}/${SVG_FILE}"
        OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/${OUTPUT_FILE}"
        MAIN_DEPENDENCY "${CMAKE_CURRENT_SOURCE_DIR}/${SVG_FILE}"
    )
    ADD_CUSTOM_TARGET( "${ADD_INKSCAPE_BITMAP_TARGET}"
        DEPENDS
            "${CMAKE_CURRENT_BINARY_DIR}/${OUTPUT_FILE}"
            ${ADD_INKSCAPE_BITMAP_DEPENDS}
    )
    
    FOREACH( DEPENDEE IN LISTS ADD_INKSCAPE_BITMAP_DEPENDEES )
        ADD_DEPENDENCIES( "${DEPENDEE}" "${ADD_INKSCAPE_BITMAP_TARGET}" )
    ENDFOREACH()
    
    IF( ADD_INKSCAPE_BITMAP_CREATE_INSTALL_RULE )
        INSTALL(
            FILES "${CMAKE_CURRENT_BINARY_DIR}/${OUTPUT_FILE}"
            DESTINATION "${ADD_INKSCAPE_BITMAP_OUTPUT_DIR}"
        )
    ENDIF()
ENDFUNCTION()
