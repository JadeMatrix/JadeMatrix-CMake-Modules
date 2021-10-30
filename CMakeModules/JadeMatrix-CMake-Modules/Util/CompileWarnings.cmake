#[=======================================================================[.rst:
JadeMatrix-CMake-Modules/Util/CompileWarnings
---------------------------------------------

.. command:: SET_ALL_COMPILE_WARNINGS
    
    SET_ALL_COMPILE_WARNINGS(
        ( <target> | <variable> )
        [ AS_ERRORS ]
        [ ASSEMBLE_ONLY ]
    )
    
    Apply the maximum set of compile warning options to a target, or output them
    as a list of generator expressions.
    
    If ``ASSEMBLE_ONLY`` is specified, the list of generator expressions will be
    set as a variable named ``<variable>``.  Otherwise, they are applied
    directly to ``<target>``'s compile options.
    
    If ``AS_ERRORS`` is specified, an option will be added to treat all compile
    warnings as errors.

.. command:: SET_COMPILE_WARNING_FOR
    
    SET_COMPILE_WARNING_FOR(
        ( <target> | <variable> )
        <option>
        [ COMPILERS <cmake-compiler-id>... ]
        [ LANGUAGES <cmake-language-id>... ]
        [ ASSEMBLE_ONLY ]
        [ NO_CACHE ]
    )
    
    Apply a single compile warning option ``<option>`` to a target, or output it
    as a generator expression.  Intended as an implementation detail of
    :command:`SET_ALL_COMPILE_WARNINGS`, this function can be used instead when
    more control is required.
    
    The set of compilers that support ``<option>`` can be speficied with
    ``COMPILERS``, where each ``<cmake-compiler-id>`` is one of
    `CMake's compiler IDs <https://cmake.org/cmake/help/latest/variable/CMAKE_LANG_COMPILER_ID.html>`.
    Likewise, the set of languages those compilers support ``<option>` for can
    be specified with ``LANGUAGES``, where each ``<cmake-language-id>`` is a
    language name recognized by CMake.  If ``COMPILERS`` and/or ``LANGUAGES`` is
    not specified, it will be assumed all compilers and/or all languages support
    ``<option>``, respectively.
    
    If ``ASSEMBLE_ONLY`` is specified, the generator expression will be set as a
    variable named ``<variable>``.  Otherwise, it is applied directly to
    ``<target>``'s compile options.
    
    Typically the generator expression for ``<option>`` will be created once and
    then cached; it is assumed the set of supporting compilers & supported
    languages will not change frequently.  To disable this, specify
    ``NO_CACHE``.

.. variable:: JMCM_COMPILE_WARNINGS_GNULIKE_C
    
    Full set of compile warning options supported by GCC, Clang, AppleClang, and
    Intel for C and C++

.. variable:: JMCM_COMPILE_WARNINGS_GNUONLY_C
    
    Full set of compile warning options supported only by GCC for C and C++

.. variable:: JMCM_COMPILE_WARNINGS_GNULIKE_CXX
    
    Full set of compile warning options supported by GCC, Clang, AppleClang, and
    Intel for C++ only

.. variable:: JMCM_COMPILE_WARNINGS_MSVC
    
    Full set of compile warning options supported by MSVC
#]=======================================================================]

CMAKE_MINIMUM_REQUIRED( VERSION 3.5 FATAL_ERROR #[[
    Requiring 3.0+:
        STRING( SHA256 ... )
    Requiring 3.5+:
        CMAKE_PARSE_ARGUMENTS( ... )
    Requiring 3.18+ (suboptimal workaround exists):
        STRING( HEX ... )
]] )


SET( JMCM_COMPILE_WARNINGS_GNULIKE_C
    "-Wall"
    "-Wextra"
    "-Wshadow"
    "-Wcast-align"
    "-Wunused"
    "-Wpedantic"
    "-Wconversion"
    "-Wsign-conversion"
    "-Wnull-dereference"
    "-Wdouble-promotion"
    "-Wformat=2"
)
SET( JMCM_COMPILE_WARNINGS_GNUONLY_C
    "-Wduplicated-cond"
    "-Wduplicated-branches"
    "-Wlogical-op"
    "-Wuseless-cast"
)
SET( JMCM_COMPILE_WARNINGS_GNULIKE_CXX
    "-Wnon-virtual-dtor"
    "-Wold-style-cast"
    "-Woverloaded-virtual"
)
SET( JMCM_COMPILE_WARNINGS_MSVC
    "/Wall"
)


FUNCTION( SET_COMPILE_WARNING_FOR TARGET OPTION )
    CMAKE_PARSE_ARGUMENTS( "SET_COMPILE_WARNING_FOR"
        "ASSEMBLE_ONLY;NO_CACHE"
        ""
        "COMPILERS;LANGUAGES"
        ${ARGN}
    )
    
    IF( CMAKE_VERSION VERSION_GREATER_EQUAL "3.18" )
        STRING( HEX "${OPTION}" CACHE_VARIABLE_NAME )
    ELSE()
        STRING( SHA256 CACHE_VARIABLE_NAME "${OPTION}" )
    ENDIF()
    SET( CACHE_VARIABLE_NAME
        "JM_CMAKE_MODULES_COMPILE_WARNINGS_${CACHE_VARIABLE_NAME}"
    )
    
    IF( NOT DEFINED ${CACHE_VARIABLE_NAME} )
        LIST( LENGTH SET_COMPILE_WARNING_FOR_COMPILERS NUM_COMPILERS )
        LIST( LENGTH SET_COMPILE_WARNING_FOR_LANGUAGES NUM_LANGUAGES )
        
        SET( COMPILER_CHECK "" )
        SET( LANGUAGE_CHECK "" )
        
        IF( NUM_COMPILERS GREATER 0 )
            SET( COMPILER_CHECK "" )
            FOREACH( COMPILER IN LISTS SET_COMPILE_WARNING_FOR_COMPILERS )
                LIST( APPEND COMPILER_CHECK "$<CXX_COMPILER_ID:${COMPILER}>" )
            ENDFOREACH()
            
            IF( NUM_COMPILERS GREATER 1 )
                STRING( REPLACE ";" "," COMPILER_CHECK "${COMPILER_CHECK}" )
                SET( COMPILER_CHECK "$<OR:${COMPILER_CHECK}>" )
            ENDIF()
        ENDIF()
        
        IF( NUM_LANGUAGES GREATER 0 )
            SET( LANGUAGE_CHECK "" )
            FOREACH( LANGUAGE IN LISTS SET_COMPILE_WARNING_FOR_LANGUAGES )
                LIST( APPEND LANGUAGE_CHECK "$<COMPILE_LANGUAGE:${LANGUAGE}>" )
            ENDFOREACH()
            
            IF( NUM_LANGUAGES GREATER 1 )
                STRING( REPLACE ";" "," LANGUAGE_CHECK "${LANGUAGE_CHECK}" )
                SET( LANGUAGE_CHECK "$<OR:${LANGUAGE_CHECK}>" )
            ENDIF()
        ENDIF()
        
        IF(
                COMPILER_CHECK STREQUAL ""
            AND LANGUAGE_CHECK STREQUAL ""
        )
            LIST( APPEND ${CACHE_VARIABLE_NAME} "${OPTION}" )
        ELSEIF(
                COMPILER_CHECK STREQUAL ""
            OR  LANGUAGE_CHECK STREQUAL ""
        )
            LIST( APPEND ${CACHE_VARIABLE_NAME}
                "$<IF:${COMPILER_CHECK}${LANGUAGE_CHECK},${OPTION},>"
            )
        ELSE()
            LIST( APPEND ${CACHE_VARIABLE_NAME}
                "$<IF:$<AND:${COMPILER_CHECK},${LANGUAGE_CHECK}>,${OPTION},>"
            )
        ENDIF()
    ENDIF()
    
    IF( NOT SET_COMPILE_WARNING_FOR_NO_CACHE )
        GET_PROPERTY( IS_CACHED CACHE ${CACHE_VARIABLE_NAME} PROPERTY TYPE )
        IF( NOT IS_CACHED )
            SET( ${CACHE_VARIABLE_NAME} "${${CACHE_VARIABLE_NAME}}"
                CACHE INTERNAL
                "Generator expression for enabling ${OPTION} via JadeMatrix-CMake-Modules/Util/CompileWarnings"
            )
        ENDIF()
    ENDIF()
    
    IF( SET_COMPILE_WARNING_FOR_ASSEMBLE_ONLY )
        SET( ${TARGET} "${${CACHE_VARIABLE_NAME}}" PARENT_SCOPE )
    ELSE()
        TARGET_COMPILE_OPTIONS( ${TARGET} PRIVATE ${${CACHE_VARIABLE_NAME}} )
    ENDIF()
ENDFUNCTION()


FUNCTION( SET_ALL_COMPILE_WARNINGS TARGET )
    CMAKE_PARSE_ARGUMENTS( "SET_ALL_COMPILE_WARNINGS"
        "AS_ERRORS;ASSEMBLE_ONLY"
        ""
        ""
        ${ARGN}
    )
    
    IF( NOT DEFINED JM_CMAKE_MODULES_ALL_COMPILE_WARNINGS )
        IF( SET_ALL_COMPILE_WARNINGS_ASSEMBLE_ONLY )
            SET( SET_ON_STRING "TEMP_WARNING_OPTION" )
            SET( ASSEMBLE_ONLY_STRING "ASSEMBLE_ONLY" )
        ELSE()
            SET( SET_ON_STRING "${TARGET}" )
            SET( ASSEMBLE_ONLY_STRING )
        ENDIF()
        
        FOREACH( OPTION IN LISTS JMCM_COMPILE_WARNINGS_GNULIKE_C )
            SET_COMPILE_WARNING_FOR( ${SET_ON_STRING}
                "${OPTION}"
                ${ASSEMBLE_ONLY_STRING}
                COMPILERS "GNU" "Clang" "AppleClang" "Intel"
                LANGUAGES "C" "CXX"
            )
            LIST( APPEND JM_CMAKE_MODULES_ALL_COMPILE_WARNINGS
                "${TEMP_WARNING_OPTION}"
            )
        ENDFOREACH()
        FOREACH( OPTION IN LISTS JMCM_COMPILE_WARNINGS_GNUONLY_C )
            SET_COMPILE_WARNING_FOR( ${SET_ON_STRING}
                "${OPTION}"
                ${ASSEMBLE_ONLY_STRING}
                COMPILERS "GNU"
                LANGUAGES "C" "CXX"
            )
            LIST( APPEND JM_CMAKE_MODULES_ALL_COMPILE_WARNINGS
                "${TEMP_WARNING_OPTION}"
            )
        ENDFOREACH()
        FOREACH( OPTION IN LISTS JMCM_COMPILE_WARNINGS_GNULIKE_CXX )
            SET_COMPILE_WARNING_FOR( ${SET_ON_STRING}
                "${OPTION}"
                ${ASSEMBLE_ONLY_STRING}
                COMPILERS "GNU" "Clang" "AppleClang" "Intel"
                LANGUAGES "CXX"
            )
            LIST( APPEND JM_CMAKE_MODULES_ALL_COMPILE_WARNINGS
                "${TEMP_WARNING_OPTION}"
            )
        ENDFOREACH()
        FOREACH( OPTION IN LISTS JMCM_COMPILE_WARNINGS_MSVC )
            SET_COMPILE_WARNING_FOR( ${SET_ON_STRING}
                "${OPTION}"
                ${ASSEMBLE_ONLY_STRING}
                COMPILERS "MSVC"
            )
            LIST( APPEND JM_CMAKE_MODULES_ALL_COMPILE_WARNINGS
                "${TEMP_WARNING_OPTION}"
            )
        ENDFOREACH()
    ENDIF()
    
    GET_PROPERTY( IS_CACHED
        CACHE JM_CMAKE_MODULES_ALL_COMPILE_WARNINGS
        PROPERTY TYPE
    )
    IF( NOT IS_CACHED )
        SET(
            JM_CMAKE_MODULES_ALL_COMPILE_WARNINGS
            "${JM_CMAKE_MODULES_ALL_COMPILE_WARNINGS}"
            CACHE INTERNAL
            "Generator expressions for all warnings enabled by JadeMatrix-CMake-Modules/Util/CompileWarnings"
        )
    ENDIF()
    
    # Warning options with warnings-as-errors appended
    SET( WARNING_OPTIONS ${JM_CMAKE_MODULES_ALL_COMPILE_WARNINGS})
    
    IF( SET_ALL_COMPILE_WARNINGS_AS_ERRORS )
        SET_COMPILE_WARNING_FOR( ${SET_ON_STRING}
            "-Werror"
            ${ASSEMBLE_ONLY_STRING}
            COMPILERS "GNU" "Clang" "AppleClang" "Intel"
            LANGUAGES "C" "CXX"
        )
        LIST( APPEND WARNING_OPTIONS "${TEMP_WARNING_OPTION}" )
        SET_COMPILE_WARNING_FOR( ${SET_ON_STRING}
            "/WX"
            ${ASSEMBLE_ONLY_STRING}
            COMPILERS "MSVC"
            LANGUAGES "C" "CXX"
        )
        LIST( APPEND WARNING_OPTIONS "${TEMP_WARNING_OPTION}" )
    ENDIF()
    
    IF( SET_ALL_COMPILE_WARNINGS_ASSEMBLE_ONLY )
        SET( ${TARGET} "${WARNING_OPTIONS}" PARENT_SCOPE )
    ENDIF()
ENDFUNCTION()
