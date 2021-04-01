#[=======================================================================[.rst:
JadeMatrix-CMake-Modules/Util/AddCompileTest
--------------------------------------

.. command:: ADD_COMPILE_TEST
    
    ADD_COMPILE_TEST(
        <name>
        [ WILL_FAIL ]
        [ FILE <filename> ]
        [ TARGET <target-name> ]
        [ COMPILE_OPTIONS <option>... ]
        [ LINK_LIBRARIES <target>... ]
        [ DEPENDS_TARGETS <target>... ]
    )
    
    Add a test named ``<name>`` that checks that some C++ code compiles.
    
    The options are:
    
    ``WILL_FAIL``
        Mark the test as `WILL_FAIL <https://cmake.org/cmake/help/latest/prop_test/WILL_FAIL.html>`_.
    
    ``FILE <filename>``
        Source file to compile; defaults to ``<name>.cpp`` 
    
    ``TARGET <target-name>``
        Name of generated target to compile; defaults to ``<name>_compiles``
    
    ``COMPILE_OPTIONS <option>...``
        Additional options to use when compiling the test; passed to
        ``TARGET_COMPILE_OPTIONS()``
    
    ``LINK_LIBRARIES <target>...``
        Other targets to pass to ``TARGET_LINK_LIBRARIES()`` for the test target
    
    ``DEPENDS_TARGETS <target>...``
        Other targets to build as part of the test before the actual compile
        test
#]=======================================================================]

CMAKE_MINIMUM_REQUIRED( VERSION 3.5 #[[
    Requiring 3.12+ (workaround exists):
        ADD_LIBRARY( foo OBJECT ) TARGET_LINK_LIBRARIES( foo ... )
    Requiring 3.5+:
        CMAKE_PARSE_ARGUMENTS( ... )
]] )

FUNCTION( ADD_COMPILE_TEST TEST_NAME )
    CMAKE_PARSE_ARGUMENTS( TEST
        "WILL_FAIL"
        "FILE"
        "COMPILE_OPTIONS;LINK_LIBRARIES;DEPENDS_TARGETS"
        ${ARGN}
    )
    
    IF( NOT TEST_FILE )
        SET( TEST_FILE "${TEST_NAME}.cpp" )
    ENDIF()
    IF( NOT TEST_TARGET )
        SET( TEST_TARGET "${TEST_NAME}_compiles" )
    ENDIF()
    
    # Add library because we aren't testing failure to link; OBJECT because it
    # has the least semantics; EXCLUDE_FROM_ALL is important in case WILL_FAIL
    # is set on this test
    UNSET( COMPILE_TEST_LIB_TYPE )
    IF( "${CMAKE_VERSION}" VERSION_GREATER_EQUAL "3.12" )
        # Allowing OBJECT libraries to link against other things was only added
        # in 3.12; else use the default library type
        SET( COMPILE_TEST_LIB_TYPE OBJECT )
    ENDIF()
    ADD_LIBRARY( ${TEST_TARGET}
        ${COMPILE_TEST_LIB_TYPE}
        EXCLUDE_FROM_ALL
        "${TEST_FILE}"
    )
    TARGET_LINK_LIBRARIES( ${TEST_TARGET}
        PRIVATE ${TEST_LINK_LIBRARIES}
    )
    TARGET_COMPILE_OPTIONS( ${TEST_TARGET}
        PRIVATE ${TEST_COMPILE_OPTIONS}
    )
    
    SET( DEPENDS_TESTS )
    FOREACH( DEPENDS_TARGET IN LISTS DEPENDS_TARGETS )
        SET( DEPENDS_TEST_NAME "${TEST_TARGET}_${DEPENDS_TARGET}" )
        ADD_TEST(
            NAME ${DEPENDS_TEST_NAME}
            COMMAND "${CMAKE_COMMAND}"
                --build "${CMAKE_BINARY_DIR}"
                --target "${DEPENDS_TARGET}"
            WORKING_DIRECTORY "${PROJECT_BINARY_DIR}"
        )
        LIST( APPEND DEPENDS_TESTS ${DEPENDS_TEST_NAME} )
    ENDFOREACH()
    
    # Test to build the OBJECT library
    ADD_TEST(
        NAME "${TEST_NAME}"
        COMMAND "${CMAKE_COMMAND}"
            --build "${CMAKE_BINARY_DIR}"
            --target "${TEST_TARGET}"
        WORKING_DIRECTORY "${PROJECT_BINARY_DIR}"
    )
    SET_TESTS_PROPERTIES( "${TEST_NAME}"
        PROPERTIES
            FIXTURES_SETUP "${DEPENDS_TESTS}"
            WILL_FAIL "${TEST_WILL_FAIL}"
    )
ENDFUNCTION()
