#[=======================================================================[.rst:
JadeMatrix-CMake-Modules/Find/Findsimd
--------------------------------------

Searches for an implementation of the C++ Parallelism TS 2 Clause 9 "simd"
support library.

If the library is found, ``SIMD_FOUND`` is set to ``TRUE`` and a library target
``simd`` is defined that carries the necessary properties for using the library.
Otherwise, ``SIMD_FOUND`` is ``FALSE``.

The ``simd`` target carries a compile definition for the "simd" feature test
macro (either ``__cpp_lib_parallel_simd`` or
``__cpp_lib_experimental_parallel_simd``) unless it is defined by the current
compiler's ``<version>`` header.

.. note::
    Parallelism TS 2 Clause 9 has not been accepted for standardization, so
    `__cpp_lib_parallel_simd` does not have a known value, and even whether the
    feature test macro name will end up as `__cpp_lib_parallel_simd` is just a
    guess.

Searches for, in order:

* ``<simd>`` then ``<experimental/simd>`` in a path manually specified with
  ``JM_SIMD_INCLUDE_DIR``
* ``<simd>`` then ``<experimental/simd>`` in the current compiler's standard
  library; this could be an installed copy of
  `VcDevel/std-simd <https://github.com/VcDevel/std-simd>`_
* `Twon/std-experimental-simd <https://github.com/Twon/std-experimental-simd>`_,
  first if added by subproject, then via its CMake package configuration

``JM_SIMD_INCLUDE_DIR`` is searched first to allow the user to override an
automatically discovered "differently-conforming" implementation if necessary.
#]=======================================================================]


FUNCTION( _JM_FINDSIMD_TRY_COMPILER_SIMD HEADER FEATURE_MACRO FEATURE_VALUE )
    SET( BINDIR "${PROJECT_BINARY_DIR}/Findsimd.temp/" )
    SET( TEST_SOURCE
        "${BINDIR}/CMakeFiles/CMakeTmp/jm_findsimd_simd_check.cpp"
    )
    FILE( WRITE "${TEST_SOURCE}"
        "#include <${HEADER}>\n"
        "int main(int, char*[]){return 0;}\n"
    )
    TRY_COMPILE( HAS_SIMD
        "${BINDIR}"
        "${TEST_SOURCE}"
        CXX_STANDARD 17
    )
    IF( HAS_SIMD )
        ADD_LIBRARY( simd INTERFACE IMPORTED )
        FILE( WRITE "${TEST_SOURCE}"
            "#include <version>\n"
            "#ifndef ${FEATURE_MACRO}\n"
            "#error no ${FEATURE_MACRO}\n"
            "#endif\n"
            "int main(int, char*[]){return 0;}\n"
        )
        TRY_COMPILE( HAS_SIMD_FEATURE_MACRO
            "${BINDIR}"
            "${TEST_SOURCE}"
            CXX_STANDARD 17
        )
        IF( NOT HAS_SIMD_FEATURE_MACRO )
            SET_TARGET_PROPERTIES( simd PROPERTIES
                INTERFACE_COMPILE_DEFINITIONS
                    "${FEATURE_MACRO}=${FEATURE_VALUE}"
            )
        ENDIF()
    ENDIF()
ENDFUNCTION()

FUNCTION( _JM_FINDSIMD_TRY_MANUAL_SIMD
    ABS_DIR
    HEADER
    FEATURE_MACRO
    FEATURE_VALUE
)
    IF(
        EXISTS "${ABS_DIR}/${HEADER}"
        AND NOT IS_DIRECTORY "${ABS_DIR}/${HEADER}"
    )
        ADD_LIBRARY( simd INTERFACE IMPORTED )
        SET_TARGET_PROPERTIES( simd PROPERTIES
            INTERFACE_INCLUDE_DIRECTORIES "${ABS_DIR}"
            INTERFACE_COMPILE_DEFINITIONS "${FEATURE_MACRO}=${FEATURE_VALUE}"
        )
    ENDIF()
ENDFUNCTION()

FUNCTION( _JM_FINDSIMD_TRY_TARGET_SIMD TARGET_NAME )
    IF( TARGET ${TARGET_NAME} )
        ADD_LIBRARY( simd INTERFACE IMPORTED )
        TARGET_LINK_LIBRARIES( simd INTERFACE ${TARGET_NAME} )
        SET_TARGET_PROPERTIES( simd PROPERTIES
            INTERFACE_COMPILE_DEFINITIONS
                "__cpp_lib_experimental_parallel_simd=201803"
        )
    ENDIF()
ENDFUNCTION()


################################################################################

SET( SIMD_FOUND FALSE )
IF( TARGET simd )
    SET( SIMD_FOUND TRUE )
    RETURN()
ENDIF()


# Manually specified location ##################################################

IF( DEFINED JM_SIMD_INCLUDE_DIR )
    GET_FILENAME_COMPONENT( ABS_DIR "${JM_SIMD_INCLUDE_DIR}" ABSOLUTE )
    
    _JM_FINDSIMD_TRY_MANUAL_SIMD(
        "${ABS_DIR}"
        "simd"
        "__cpp_lib_parallel_simd"
        "201803"
    )
    IF( TARGET simd )
        SET( SIMD_FOUND TRUE )
        RETURN()
    ENDIF()
    
    _JM_FINDSIMD_TRY_MANUAL_SIMD(
        "${ABS_DIR}"
        "experimental/simd"
        "__cpp_lib_experimental_parallel_simd"
        "201803"
    )
    IF( TARGET simd )
        SET( SIMD_FOUND TRUE )
        RETURN()
    ENDIF()
    
    IF( NOT simd_FIND_QUIETLY )
        MESSAGE( WARNING
            "JM_SIMD_INCLUDE_DIR was manually specified but does not contain "
            "<simd> or <experimental/simd>; checking elsewhere"
        )
    ENDIF()
ENDIF()


# Compiler-supported (may be installed version of VcDevel/std-simd) ############

_JM_FINDSIMD_TRY_COMPILER_SIMD( "simd" "__cpp_lib_parallel_simd" "201803" )
IF( TARGET simd )
    SET( SIMD_FOUND TRUE )
    RETURN()
ENDIF()

_JM_FINDSIMD_TRY_COMPILER_SIMD(
    "experimental/simd"
    "__cpp_lib_experimental_parallel_simd"
    "201803"
)
IF( TARGET simd )
    SET( SIMD_FOUND TRUE )
    RETURN()
ENDIF()


# Twon/std-experimental-simd ###################################################

# Included via subproject
_JM_FINDSIMD_TRY_TARGET_SIMD( std_experimental_simd )
IF( TARGET simd )
    SET( SIMD_FOUND TRUE )
    RETURN()
ENDIF()

# Found via `FIND_PACKAGE()`
IF( NOT TARGET std_experimental_simd::std_experimental_simd )
    FIND_PACKAGE( std_experimental_simd
        QUIET
        COMPONENTS std_experimental_simd
    )
ENDIF()
_JM_FINDSIMD_TRY_TARGET_SIMD( std_experimental_simd::std_experimental_simd )
IF( TARGET simd )
    SET( SIMD_FOUND TRUE )
    RETURN()
ENDIF()


################################################################################

IF( simd_FIND_REQUIRED )
    IF( DEFINED JM_SIMD_INCLUDE_DIR )
        MESSAGE( FATAL_ERROR
            "Failed to find simd (JM_SIMD_INCLUDE_DIR=${JM_SIMD_INCLUDE_DIR})"
        )
    ELSE()
        MESSAGE( FATAL_ERROR
            "Failed to find simd; try setting JM_SIMD_INCLUDE_DIR to the "
            "directory containing your <simd> or <experimental/simd> header"
        )
    ENDIF()
ENDIF()
