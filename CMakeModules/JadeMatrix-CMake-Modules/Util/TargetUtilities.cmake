#[=======================================================================[.rst:
JadeMatrix-CMake-Modules/Util/TargetUtilities.cmake
---------------------------------------------------

.. command:: LIST_TARGETS
    
    LIST_TARGETS(
        <out-var>
        [ DIRECTORIES <directory>... ]
        [ CATEGORIES <category>... ]
    )
    
    Helper function for recursively listing targets added in the specified
    directories.  If no directories are specified, ``CMAKE_CURRENT_SOURCE_DIR``
    is used.
    
    ``CATEGORIES`` can one or more of ``BUILDSYSTEM``, ``IMPORTED``, or
    ``ALL`` (``ALL`` implies the other two).  The default is just
    ``BUILDSYSTEM`` targets; listing ``IMPORTED`` targets requries CMake 3.21 or
    higher.
    
    There is no ``NO_RECURSE`` option, as a directory's
    `BUILDSYSTEM_TARGETS <https://cmake.org/cmake/help/latest/prop_dir/BUILDSYSTEM_TARGETS.html>`
    and
    `IMPORTED_TARGETS <https://cmake.org/cmake/help/latest/prop_dir/IMPORTED_TARGETS.html>`
    properties can just be obtained instead.
    
.. command:: PREPROCESS_TARGET_SOURCES
    
    PREPROCESS_TARGET_SOURCES(
        <target>
        SCRIPT <script>
        [ DEFINES ( <variable> | <variable>=<value> )... ]
        [ FILTER <function-name> ]
        [ NO_SKIP_EXTERNAL ]
        [ NO_SKIP_INCLUDES ]
        [ GLOB_INCLUDES | GLOB_CONFIGURE_DEPENDS_INCLUDES ]
    )
    
    Configure custom commands to modify a target's source files using a CMake
    script as part of the build process.  If ``SCRIPT`` is a relative path, it
    is assumed to be relative to `CMAKE_CURRENT_SOURCE_DIR`.
    
    A number of variables are passed to the specified script:
    
    - ``INPUT_FILENAME`` — Absolute filename of the original source file to read
    - ``OUTPUT_FILENAME`` — Absolute filename of the processed file to write
    - ``TARGET_NAME`` — Name of the target for which this file is being
      preprocessed
    - ``TARGET_SOURCE_DIR`` — The target's source directory
    - ``TARGET_BINARY_DIR`` — THe target's binary directory
    - ``PROJECT_SOURCE_DIR``
    - ``PROJECT_BINARY_DIR``
    
    As CMake
    `defines these variables specially in script mode <https://cmake.org/cmake/help/latest/variable/CMAKE_CURRENT_SOURCE_DIR.html`,
    ``ORIG_***`` versions are also supplied:
    
    - ``ORIG_CMAKE_SOURCE_DIR``
    - ``ORIG_CMAKE_BINARY_DIR``
    - ``ORIG_CMAKE_CURRENT_SOURCE_DIR``
    - ``ORIG_CMAKE_CURRENT_BINARY_DIR``
    
    Additional user-specified variables can be specified using the ``DEFINES``
    argument.
    
    Whether a given source file is selected for preprocessing can be determined
    using a function passed by name using ``FILTER``; this requires CMake 3.18
    or higher.  The filter function is called with a single argument, the
    absolute path of the source file.  The function must then set a variable
    called ``SHOULD_PREPROCESS_FILE`` in the parent scope set to a boolean
    value.
    
    By default, source files external to the project are not preprocessed, and
    include directories are not checked.  These can be overridden with
    ``NO_SKIP_EXTERNAL`` and ``NO_SKIP_INCLUDES``, respectively.
    
    If ``NO_SKIP_INCLUDES`` is specified, ``PREPROCESS_TARGET_SOURCES()``
    assumes all header files are included in the target's ``SOURCES`` property.
    ``GLOB_INCLUDES`` or ``GLOB_CONFIGURE_DEPENDS_INCLUDES`` (CMake 3.21+)
    can be specified to search for additional header files in the target's
    include directories.  As globbing during the CMake configure step
    `is officially discouraged <https://cmake.org/cmake/help/latest/command/file.html#glob-recurse>`
    as it can
    `lead to poor build performance <https://discourse.cmake.org/t/is-glob-still-considered-harmful-with-configure-depends/808>`
    or
    `not even work with some generators (e.g. VS, Xcode) <https://github.com/google/iree/issues/1083#issuecomment-599146458>`,
    it is recommended to only use these options if absolutely necessary.
    
.. command:: PREPROCESS_TARGET_SOURCE
    
    PREPROCESS_TARGET_SOURCE(
        <out-var>
        <target>
        <target-source>
        SCRIPT <script>
        [ NO_SKIP_EXTERNAL ]
        [ FILTER <function-name> ]
        [ TARGET_SOURCE_DIR <directory> ]
        [ TARGET_BINARY_DIR <directory> ]
        [ DEFINES ( <variable> | <variable>=<value> )... ]
    )
    
    Configure a custom command to modify a single source file
    ``<target-source>`` for a target using a CMake script as part of the build
    process.  Intended as a helper function for ``PREPROCESS_TARGET_SOURCES()``;
    ``SCRIPT``, ``NO_SKIP_EXTERNAL``, ``FILTER``, and ``DEFINES`` are used the
    same way.
    
    ``<out-var>`` will be set to either the name of the processed source file if
    it was configured, or ``<target-source>`` if it was not for any reason.
    
    ``TARGET_SOURCE_DIR`` and ``TARGET_BINARY_DIR`` may be passed in as an
    optimization; if they are not specified, they are obtained from the target's
    properties.
#]=======================================================================]

CMAKE_MINIMUM_REQUIRED( VERSION 3.7 FATAL_ERROR #[[
    Requiring 3.2+:
        CONTINUE()
    Requiring 3.3+ (optional behavior):
        FILE( GLOB_RECURSE ... LIST_DIRECTORIES TRUE )
    Requiring 3.4+:
        Target property BINARY_DIR
        Target property SOURCE_DIR
    Requiring 3.5+:
        CMAKE_PARSE_ARGUMENTS( ... )
    Requiring 3.7+:
        Directory property BUILDSYSTEM_TARGETS
        Directory property SUBDIRECTORIES
    Requiring 3.12+ (optional behavior):
        FILE( GLOB_RECURSE ... CONFIGURE_DEPENDS )
    Requiring 3.18+ (optional behavior):
        CMAKE_LANGUAGE( ... )
    Requiring 3.21+ (optional behavior):
        Directory property IMPORTED_TARGETS
]] )


FUNCTION( LIST_TARGETS OUT_VAR )
    CMAKE_PARSE_ARGUMENTS( ""
        ""
        ""
        "DIRECTORIES;CATEGORIES"
        ${ARGN}
    )
    
    IF( NOT DEFINED _DIRECTORIES )
        SET( _DIRECTORIES "${CMAKE_CURRENT_SOURCE_DIR}" )
    ENDIF()
    
    IF( NOT DEFINED _CATEGORIES )
        SET( _CATEGORIES "BUILDSYSTEM" )
    ELSEIF( "ALL" IN_LIST _CATEGORIES )
        SET( _CATEGORIES "BUILDSYSTEM" "IMPORTED" )
    ELSE()
        LIST( REMOVE_DUPLICATES _CATEGORIES )
        FOREACH( CATEGORY IN LISTS _CATEGORIES )
            IF(
                    NOT CATEGORY STREQUAL "BUILDSYSTEM"
                AND NOT CATEGORY STREQUAL "IMPORTED"
            )
                MESSAGE( SEND_ERROR
                    "LIST_TARGETS() given invalid target category ${CATEGORY}"
                )
            ENDIF()
        ENDFOREACH()
    ENDIF()
    
    IF( CMAKE_VERSION VERSION_LESS 3.21 AND "IMPORTED" IN_LIST _CATEGORIES )
        MESSAGE( SEND_ERROR
            "LIST_TARGETS() given target category IMPORTED which requires "
            "CMake version 3.21 or higher"
        )
    ENDIF()
    
    SET( ALL_TARGETS )
    
    FOREACH( CHILD IN LISTS _DIRECTORIES )
        IF( NOT IS_ABSOLUTE "${CHILD}")
            SET( CHILD "${CMAKE_CURRENT_SOURCE_DIR}/${CHILD}")
        ENDIF()
        
        IF( IS_DIRECTORY "${CHILD}" )
            FOREACH( CATEGORY IN LISTS _CATEGORIES )
                GET_DIRECTORY_PROPERTY( TARGETS
                    DIRECTORY "${CHILD}"
                    ${CATEGORY}_TARGETS
                )
                LIST( APPEND ALL_TARGETS ${TARGETS} )
            ENDFOREACH()
            
            GET_DIRECTORY_PROPERTY( CHILDREN
                DIRECTORY "${CHILD}"
                SUBDIRECTORIES
            )
            LIST( LENGTH CHILDREN NUM_CHILDREN )
            IF( NUM_CHILDREN GREATER 0 )
                LIST_TARGETS( TARGETS
                    DIRECTORIES ${CHILDREN}
                    CATEGORIES  ${_CATEGORIES}
                )
                LIST( APPEND ALL_TARGETS ${TARGETS} )
            ENDIF()
        ENDIF()
    ENDFOREACH()
    
    SET( "${OUT_VAR}" "${ALL_TARGETS}" PARENT_SCOPE )
ENDFUNCTION()


FUNCTION( PREPROCESS_TARGET_SOURCE OUT_VAR TARGET TARGET_SOURCE )
    CMAKE_PARSE_ARGUMENTS( ""
        "NO_SKIP_EXTERNAL"
        "SCRIPT;FILTER;TARGET_SOURCE_DIR;TARGET_BINARY_DIR"
        "DEFINES"
        ${ARGN}
    )
    
    IF( NOT DEFINED _SCRIPT )
        MESSAGE( FATAL_ERROR
            "PREPROCESS_TARGET_SOURCE() called without SCRIPT argument"
        )
    ELSEIF( NOT IS_ABSOLUTE "${_SCRIPT}" )
        SET( _SCRIPT "${CMAKE_CURRENT_SOURCE_DIR}/${_SCRIPT}" )
    ENDIF()
    
    IF( DEFINED _FILTER AND CMAKE_VERSION VERSION_LESS 3.18 )
        MESSAGE( FATAL_ERROR
            "PREPROCESS_TARGET_SOURCE() called with FILTER argument which "
            "requires CMake version 3.18 or higher"
        )
    ENDIF()
    
    IF( NOT DEFINED _TARGET_BINARY_DIR )
        GET_TARGET_PROPERTY( _TARGET_BINARY_DIR "${TARGET}" BINARY_DIR )
    ENDIF()
    IF( NOT DEFINED _TARGET_SOURCE_DIR )
        GET_TARGET_PROPERTY( _TARGET_SOURCE_DIR "${TARGET}" SOURCE_DIR )
    ENDIF()
    
    SET( ADD_DEFINES )
    FOREACH( DEFINE IN LISTS _DEFINES )
        LIST( APPEND ADD_DEFINES "-D" "${DEFINE}" )
    ENDFOREACH()
    
    ############################################################################
    
    IF( NOT IS_ABSOLUTE "${TARGET_SOURCE}" )
        SET( TARGET_SOURCE_ABS "${_TARGET_SOURCE_DIR}/${TARGET_SOURCE}" )
    ELSE()
        SET( TARGET_SOURCE_ABS "${TARGET_SOURCE}" )
    ENDIF()
    
    IF( NOT _NO_SKIP_EXTERNAL )
        FILE( RELATIVE_PATH REL_PATH
            "${PROJECT_SOURCE_DIR}"
            "${TARGET_SOURCE_ABS}"
        )
        IF( REL_PATH MATCHES [[^\.\./.*]] )
            SET( "${OUT_VAR}" "${TARGET_SOURCE}" PARENT_SCOPE )
            RETURN()
        ENDIF()
        SET( TARGET_SOURCE "${REL_PATH}" )
    ELSE()
        # Use absolute paths instead of project-relative paths to prevent
        # possible conflicts
        SET( TARGET_SOURCE "${TARGET_SOURCE_ABS}" )
    ENDIF()
    
    SET( PROCESSED_SOURCE
        "${_TARGET_BINARY_DIR}/processed-sources/${TARGET_SOURCE}"
    )
    # Use the hash of the path in the util target name and hope for the
    # best, because using the hex string of the path in 3.18+ runs into
    # path name length issues with the Makefile generator (at least)
    STRING( SHA256 HASHED_PATH "${PROCESSED_SOURCE}" )
    SET( PREPROCESS_SOURCE_TARGET_NAME "preprocess-source-${HASHED_PATH}" )
    
    IF( TARGET "${PREPROCESS_SOURCE_TARGET_NAME}" )
        MESSAGE( VERBOSE
            "Source file ${TARGET_SOURCE} for target ${TARGET} already marked "
            "for preprocessing"
        )
        SET( "${OUT_VAR}" "${PROCESSED_SOURCE}" PARENT_SCOPE )
        RETURN()
    ENDIF()
    
    IF( DEFINED _FILTER )
        SET( SHOULD_PREPROCESS_FILE FALSE )
        CMAKE_LANGUAGE( CALL "${_FILTER}" "${TARGET_SOURCE_ABS}" )
        IF( NOT SHOULD_PREPROCESS_FILE )
            SET( "${OUT_VAR}" "${TARGET_SOURCE}" PARENT_SCOPE )
            RETURN()
        ENDIF()
    ENDIF()
    
    # "Pretty" path for custom command comment
    FILE( RELATIVE_PATH PRETTY_SOURCE_NAME
        "${PROJECT_SOURCE_DIR}"
        "${TARGET_SOURCE_ABS}"
    )
    IF( PRETTY_SOURCE_NAME MATCHES [[^\.\./.*]] )
        SET( PRETTY_SOURCE_NAME "${TARGET_SOURCE_ABS}" )
    ENDIF()
    
    ADD_CUSTOM_COMMAND(
        OUTPUT "${PROCESSED_SOURCE}"
        COMMAND ${CMAKE_COMMAND}
            -D "INPUT_FILENAME=${TARGET_SOURCE_ABS}"
            -D "OUTPUT_FILENAME=${PROCESSED_SOURCE}"
            -D "PROJECT_SOURCE_DIR=${PROJECT_SOURCE_DIR}"
            -D "PROJECT_BINARY_DIR=${PROJECT_BINARY_DIR}"
            -D "TARGET_SOURCE_DIR=${_TARGET_SOURCE_DIR}"
            -D "TARGET_BINARY_DIR=${_TARGET_BINARY_DIR}"
            -D "TARGET_NAME=${TARGET}"
            # See https://cmake.org/cmake/help/latest/variable/CMAKE_CURRENT_SOURCE_DIR.html
            -D "ORIG_CMAKE_SOURCE_DIR=${CMAKE_SOURCE_DIR}"
            -D "ORIG_CMAKE_BINARY_DIR=${CMAKE_BINARY_DIR}"
            -D "ORIG_CMAKE_CURRENT_SOURCE_DIR=${CMAKE_CURRENT_SOURCE_DIR}"
            -D "ORIG_CMAKE_CURRENT_BINARY_DIR=${CMAKE_CURRENT_BINARY_DIR}"
            ${ADD_DEFINES}
            -P "${_SCRIPT}"
        MAIN_DEPENDENCY "${TARGET_SOURCE_ABS}"
        DEPENDS "${_SCRIPT}"
        COMMENT "Processing ${PRETTY_SOURCE_NAME}"
    )
    
    ADD_CUSTOM_TARGET( "${PREPROCESS_SOURCE_TARGET_NAME}"
        DEPENDS "${PROCESSED_SOURCE}"
    )
    ADD_DEPENDENCIES( "${TARGET}" "preprocess-source-${HASHED_PATH}" )
    
    # CMake 3.20+ is (apparently) a lot smarter about the GENERATED
    # property on source files -- need to confirm this isn't necessary
    IF( #[[ CMAKE_VERSION VERSION_LESS 3.20 ]] TRUE )
        SET_SOURCE_FILES_PROPERTIES( "${PROCESSED_SOURCE}"
            DIRECTORY "${_TARGET_SOURCE_DIR}"
            PROPERTIES
                GENERATED TRUE
        )
    ENDIF()
    
    SET( "${OUT_VAR}" "${PROCESSED_SOURCE}" PARENT_SCOPE )
ENDFUNCTION()


FUNCTION( PREPROCESS_TARGET_SOURCES TARGET )
    CMAKE_PARSE_ARGUMENTS( ""
        "NO_SKIP_EXTERNAL;NO_SKIP_INCLUDES;GLOB_INCLUDES;GLOB_CONFIGURE_DEPENDS_INCLUDES"
        "SCRIPT;FILTER"
        "DEFINES"
        ${ARGN}
    )
    
    SET( PTS_FWD_ARGS )
    
    IF( _NO_SKIP_EXTERNAL )
        LIST( APPEND PTS_FWD_ARGS "NO_SKIP_EXTERNAL" )
    ENDIF()
    
    IF( DEFINED _SCRIPT )
        LIST( APPEND PTS_FWD_ARGS "SCRIPT" "${_SCRIPT}" )
    ENDIF()
    
    IF( DEFINED _FILTER )
        LIST( APPEND PTS_FWD_ARGS "FILTER" "${_FILTER}" )
    ENDIF()
    
    IF( _GLOB_CONFIGURE_DEPENDS_INCLUDES )
        IF( CMAKE_VERSION VERSION_LESS 3.12 )
            MESSAGE( FATAL_ERROR
                "PREPROCESS_TARGET_SOURCES() called with "
                "GLOB_CONFIGURE_DEPENDS_INCLUDES argument which requires CMake "
                "version 3.12 or higher"
            )
        ENDIF()
        
        SET( _GLOB_INCLUDES TRUE )
    ENDIF()
    
    GET_TARGET_PROPERTY( TARGET_BINARY_DIR "${TARGET}" BINARY_DIR )
    GET_TARGET_PROPERTY( TARGET_SOURCE_DIR "${TARGET}" SOURCE_DIR )
    LIST( APPEND PTS_FWD_ARGS "TARGET_BINARY_DIR" "${TARGET_BINARY_DIR}" )
    LIST( APPEND PTS_FWD_ARGS "TARGET_SOURCE_DIR" "${TARGET_SOURCE_DIR}" )
    
    LIST( APPEND PTS_FWD_ARGS "DEFINES" "${_DEFINES}" )
    
    # Source files #############################################################
    
    GET_TARGET_PROPERTY( TARGET_SOURCES "${TARGET}" SOURCES )
    
    IF( TARGET_SOURCES )
        SET( NEW_TARGET_SOURCES )
        
        FOREACH( TARGET_SOURCE IN LISTS TARGET_SOURCES )
            PREPROCESS_TARGET_SOURCE( PROCESSED_SOURCE
                "${TARGET}"
                "${TARGET_SOURCE}"
                ${PTS_FWD_ARGS}
            )
            
            LIST( APPEND NEW_TARGET_SOURCES "${PROCESSED_SOURCE}" )
        ENDFOREACH()
        
        SET_TARGET_PROPERTIES( "${TARGET}"
            PROPERTIES
                SOURCES "${NEW_TARGET_SOURCES}"
        )
    ENDIF()
    
    # Include files ############################################################
    
    IF( _NO_SKIP_INCLUDES )
        SET( INCLUDE_DIR_PROPERTIES
            "INCLUDE_DIRECTORIES"
            "INTERFACE_INCLUDE_DIRECTORIES"
        )
    ELSE()
        SET( INCLUDE_DIR_PROPERTIES )
    ENDIF()
    
    FOREACH( PROPERTY IN LISTS INCLUDE_DIR_PROPERTIES )
        GET_TARGET_PROPERTY( TARGET_${PROPERTY} "${TARGET}" ${PROPERTY} )
        IF( NOT TARGET_${PROPERTY} )
            CONTINUE()
        ENDIF()
        
        SET( NEW_TARGET_${PROPERTY} )
        
        FOREACH( DIRECTORY IN LISTS TARGET_${PROPERTY} )
            UNSET( EXTRACTED_DIR )
            
            # Only use real paths and paths extract from `BUILD_INTERFACE`
            # generator expressions.  The reasoning for this is if the target is
            # built by this project, it will either have real paths or typical
            # `BUILD_INTERFACE`/`INSTALL_INTERFACE` include directories; if it
            # is imported, it will have real paths.  There's no guarantee this
            # is the case, but it's generally a good assumption, and there's no
            # reasonable way to handle special cases.
            
            # NOTE: This will fail on more complex generator expressions
            IF( "${DIRECTORY}" MATCHES [[^\$<BUILD_INTERFACE:(.*)>$]] )
                SET( DIRECTORY "${CMAKE_MATCH_1}")
            ENDIF()
            
            IF( IS_ABSOLUTE "${DIRECTORY}" AND EXISTS "${DIRECTORY}" )
                SET( EXTRACTED_DIR "${DIRECTORY}" )
            ELSEIF( EXISTS "${TARGET_SOURCE_DIR}/${DIRECTORY}" )
                SET( EXTRACTED_DIR "${TARGET_SOURCE_DIR}/${DIRECTORY}" )
            ENDIF()
            
            IF( DEFINED EXTRACTED_DIR )
                IF( _GLOB_INCLUDES )
                    IF( _GLOB_CONFIGURE_DEPENDS_INCLUDES )
                        SET( GLOB_CONFIGURE_DEPENDS "CONFIGURE_DEPENDS" )
                    ELSE()
                        SET( GLOB_CONFIGURE_DEPENDS )
                    ENDIF()
                    
                    FILE( GLOB_RECURSE TARGET_INCLUDES
                        FOLLOW_SYMLINKS
                        LIST_DIRECTORIES FALSE
                        ${GLOB_CONFIGURE_DEPENDS}
                        "${EXTRACTED_DIR}/*"
                    )
                    
                    FOREACH( TARGET_INCLUDE IN LISTS TARGET_INCLUDES )
                        PREPROCESS_TARGET_SOURCE( PROCESSED_INCLUDE
                            "${TARGET}"
                            "${TARGET_INCLUDE}"
                            ${PTS_FWD_ARGS}
                        )
                    ENDFOREACH()
                ENDIF()
                
                # Replicate is-external check from `PREPROCESS_TARGET_SOURCE()`
                # so we can use the correct incldue path
                IF( NOT _NO_SKIP_EXTERNAL )
                    FILE( RELATIVE_PATH REL_PATH
                        "${PROJECT_SOURCE_DIR}"
                        "${EXTRACTED_DIR}"
                    )
                    IF( NOT REL_PATH MATCHES [[^\.\./.*]] )
                        LIST( APPEND NEW_TARGET_${PROPERTY}
                            "$<BUILD_INTERFACE:${TARGET_BINARY_DIR}/processed-sources/${REL_PATH}>"
                        )
                    ENDIF()
                ELSE()
                    LIST( APPEND NEW_TARGET_${PROPERTY}
                        "$<BUILD_INTERFACE:${TARGET_BINARY_DIR}/processed-sources/${EXTRACTED_DIR}>"
                    )
                ENDIF()
            ENDIF()
        ENDFOREACH()
        
        LIST( REMOVE_DUPLICATES NEW_TARGET_${PROPERTY} )
        LIST( APPEND NEW_TARGET_${PROPERTY} ${TARGET_${PROPERTY}} )
        SET_TARGET_PROPERTIES( "${TARGET}"
            PROPERTIES
                ${PROPERTY} "${NEW_TARGET_${PROPERTY}}"
        )
    ENDFOREACH()
ENDFUNCTION()
