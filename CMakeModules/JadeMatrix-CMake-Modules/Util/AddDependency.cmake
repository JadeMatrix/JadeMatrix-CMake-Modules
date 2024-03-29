#[=======================================================================[.rst:
JadeMatrix-CMake-Modules/Util/AddDependency
-------------------------------------------

.. command:: ADD_DEPENDENCY
    
    ADD_DEPENDENCY(
        <name>
        [ REQUIRED ]
        [ VERSION <version> ]
        [ SUBDIRECTORY <directory> ]
        [ NAMESPACE <namespace> ]
        [ COMPONENTS <component>... ]
        [ OPTIONAL_COMPONENTS <component>... ]
        [ PROPAGATE <variable>... ]
    )
    
    Boilerplate function for defining a dependency as residing in a subdirectory
    with a fallback to ``FIND_PACKAGE()``, permitting users more flexibility in
    how they build a project.
    
    This function assumes "well-behaved" dependencies that follow CMake 3 best
    practices.
    
    The options are:
    
        ``<name>``
            Name of the dependency as it would be passed to ``FIND_PACKAGE()``
        
        ``REQUIRED``
            Mark this dependency as required (failing to find it will be a
            configure error)
        
        ``VERSION <version>``
            Specify the version of this dependency to pass to ``FIND_PACKAGE()``
            if it is called.  This is ignored if the dependency is found in the
            specified subdirectory, as it is assumed the correct version is
            there.  Additionally, detecting the version from a subdirectory
            would require parsing its CMakeLists.txt for calls to ``PROJECT()``,
            which is not deemed practical at this time.
        
        ``SUBDIRECTORY <directory>``
            Specify a subdirectory in which this dependency might be found, such
            as a `git submodule <https://git-scm.com/book/en/v2/Git-Tools-Submodules>`
        
        ``NAMESPACE <namespace>``
            The namespace prepended onto the specified component targets from
            the dependency project (e.g. "Dependency::" in the name
            "Dependency::target").  If not given, the namespace is assumed to be
            the dependency name with "::" appended.
        
        ``COMPONENTS <component>...``
            List of required component targets from the dependency project
        
        ``OPTIONAL_COMPONENTS <component>...``
            List of optional component targets from the dependency project
        
        ``PROPAGATE <variable>...``
            Variables to set in parent scope after finding the dependency, such
            as ``CMAKE_MODULE_PATH``
    
    Unlike when using ``FIND_PACKAGE()``, ``COMPONETNS`` and/or
    ``OPTIONAL_COMPONENTS`` must list all target components of the dependency
    that are used, as otherwise the correct ``ALIAS`` targets cannot be created
    when the dependency is added from a subdirectory.
    
    The variable ``<name>_FOUND`` is set if ``ADD_DEPENDECY()`` believes it
    found the dependency in the specified subdirectory, to mimic the behavior of
    ``FIND_PACKAGE()``.
    
    Note that ``ADD_DEPENDENCY()`` cannot be used to find itself (i.e. this
    project, ``JadeMatrix-CMake-Modules``).  However, the CMake code for
    bootstrapping this package in a similar fashion to ``ADD_DEPENDENCY()`` is
    relatively simple::
    
        LIST( APPEND CMAKE_MODULE_PATH
            "${PROJECT_SOURCE_DIR}/${JMCMM_LOCATION}/CMakeModules/"
            # ... where `JMCMM_LOCATION` is the subdirectory potentially
            # containing `JadeMatrix-CMake-Modules`
        )
        INCLUDE( JadeMatrix-CMake-Modules/Util/AddDependency
            OPTIONAL
            RESULT_VARIABLE JMCMM_INCLUDED
        )
        IF( NOT JMCMM_INCLUDED )
            FIND_PACKAGE( JadeMatrix-CMake-Modules 1 REQUIRED )
            INCLUDE( JadeMatrix-CMake-Modules/Util/AddDependency )
        ENDIF()
#]=======================================================================]

CMAKE_MINIMUM_REQUIRED( VERSION 3.5 FATAL_ERROR #[[
    Requiring 3.5+:
        CMAKE_PARSE_ARGUMENTS( ... )
    Requiring 3.15+ (`STATUS` used below this version):
        MESSAGE( VERBOSE ... )
]] )

FUNCTION( ADD_DEPENDENCY NAME )
    CMAKE_PARSE_ARGUMENTS( "ADD_DEPENDENCY"
        "REQUIRED"
        "VERSION;SUBDIRECTORY;NAMESPACE"
        "COMPONENTS;OPTIONAL_COMPONENTS;PROPAGATE"
        ${ARGN}
    )
    
    IF( CMAKE_VERSION VERSION_GREATER_EQUAL "3.15" )
        SET( VERBOSE_LEVEL VERBOSE )
    ELSE()
        SET( VERBOSE_LEVEL STATUS )
    ENDIF()
    
    IF( DEFINED ADD_DEPENDENCY_NAMESPACE )
        SET( NAMESPACE "${ADD_DEPENDENCY_NAMESPACE}" )
    ELSE()
        SET( NAMESPACE "${NAME}::" )
    ENDIF()
    
    SET( EXISTING_NONOPTIONAL_COMPONENTS )
    FOREACH( COMPONENT IN LISTS ADD_DEPENDENCY_COMPONENTS )
        MESSAGE( ${VERBOSE_LEVEL}
            "(ADD_DEPENDENCY) Checking if ${NAMESPACE}${COMPONENT} is a target…"
        )
        IF( TARGET "${NAMESPACE}${COMPONENT}" )
            MESSAGE( ${VERBOSE_LEVEL}
                "(ADD_DEPENDENCY) … ${NAMESPACE}${COMPONENT} is a target"
            )
            LIST( APPEND EXISTING_NONOPTIONAL_COMPONENTS
                "${NAMESPACE}${COMPONENT}"
            )
        ELSE()
            MESSAGE( ${VERBOSE_LEVEL}
                "(ADD_DEPENDENCY) … ${NAMESPACE}${COMPONENT} is NOT a target"
            )
        ENDIF()
    ENDFOREACH()
    
    IF( ADD_DEPENDENCY_REQUIRED )
        SET( FAILURE_MESSAGE_LEVEL SEND_ERROR )
    ELSE()
        SET( FAILURE_MESSAGE_LEVEL WARNING )
    ENDIF()
    
    LIST( LENGTH       ADD_DEPENDENCY_COMPONENTS ENC_EXPECTED_LEN )
    LIST( LENGTH EXISTING_NONOPTIONAL_COMPONENTS          ENC_LEN )
    IF( ENC_EXPECTED_LEN GREATER 0 AND ENC_LEN GREATER ENC_EXPECTED_LEN )
        MESSAGE( ${FAILURE_MESSAGE_LEVEL}
            "Some (but not all) components found on call to ADD_DEPENDENCY(): "
            "${EXISTING_NONOPTIONAL_COMPONENTS}"
        )
        RETURN()
    ENDIF()
    
    IF( ENC_EXPECTED_LEN EQUAL 0 )
        FOREACH( COMPONENT IN LISTS ADD_DEPENDENCY_OPTIONAL_COMPONENTS )
            IF( TARGET "${NAMESPACE}${COMPONENT}" )
                IF( NOT DEFINED "${NAME}_FOUND" )
                    SET( "${NAME}_FOUND" TRUE PARENT_SCOPE )
                ENDIF()
                RETURN()
            ENDIF()
        ENDFOREACH()
    ENDIF()
    
    IF( ENC_LEN EQUAL ENC_EXPECTED_LEN )
        MESSAGE( STATUS
            "All dependencies (${ENC_EXPECTED_LEN}) satisfied for "
            "ADD_DEPENDENCY()"
        )
        RETURN()
    ENDIF()
    
    IF(
        DEFINED ADD_DEPENDENCY_SUBDIRECTORY
        AND EXISTS "${PROJECT_SOURCE_DIR}/${ADD_DEPENDENCY_SUBDIRECTORY}/CMakeLists.txt"
    )
        ADD_SUBDIRECTORY( "${ADD_DEPENDENCY_SUBDIRECTORY}" )
        
        IF( DEFINED ADD_DEPENDENCY_VERSION )
            MESSAGE( STATUS
                "Ignoring requested version ${ADD_DEPENDENCY_VERSION} for "
                "project ${NAME} under ${ADD_DEPENDENCY_SUBDIRECTORY}"
            )
        ENDIF()
        
        SET( "${NAME}_FOUND" TRUE PARENT_SCOPE )
        FOREACH( COMPONENT IN LISTS ADD_DEPENDENCY_COMPONENTS )
            IF( TARGET "${COMPONENT}" )
                ADD_LIBRARY( "${NAMESPACE}${COMPONENT}" ALIAS "${COMPONENT}" )
            ELSEIF()
                MESSAGE( ${FAILURE_MESSAGE_LEVEL}
                    "Project ${NAME} under ${ADD_DEPENDENCY_SUBDIRECTORY} has "
                    "no target named ${COMPONENT}"
                )
                SET( "${NAME}_FOUND" FALSE PARENT_SCOPE )
            ENDIF()
        ENDFOREACH()
        
        FOREACH( COMPONENT IN LISTS ADD_DEPENDENCY_OPTIONAL_COMPONENTS )
            IF( TARGET "${COMPONENT}" )
                ADD_LIBRARY( "${NAMESPACE}${COMPONENT}" ALIAS "${COMPONENT}" )
            ENDIF()
        ENDFOREACH()
        
    ELSE()
        # Want to log about this just in case the building user forgot something
        # like `git clone --recursive`
        IF( DEFINED ADD_DEPENDENCY_SUBDIRECTORY )
            MESSAGE( STATUS
                "Directory ${ADD_DEPENDENCY_SUBDIRECTORY} does not contain a "
                "CMakeLists.txt for ${NAME}; falling back to FIND_PACKAGE()"
            )
        ENDIF()
        
        IF( ADD_DEPENDENCY_REQUIRED AND NOT "${${NAME}_FOUND}" )
            SET( FIND_PACKAGE_EXTRA_ARGS "REQUIRED" )
        ELSEIF( "${${NAME}_FOUND}" )
            SET( FIND_PACKAGE_EXTRA_ARGS "QUIET" )
        ELSE()
            SET( FIND_PACKAGE_EXTRA_ARGS )
        ENDIF()
        
        FIND_PACKAGE( "${NAME}"
            ${FIND_PACKAGE_EXTRA_ARGS}
            COMPONENTS          ${ADD_DEPENDENCY_COMPONENTS}
            OPTIONAL_COMPONENTS ${ADD_DEPENDENCY_OPTIONAL_COMPONENTS}
        )
        
    ENDIF()
    
    FOREACH( VARIABLE IN LISTS ADD_DEPENDENCY_PROPAGATE )
        SET( "${VARIABLE}" "${${VARIABLE}}" PARENT_SCOPE )
    ENDFOREACH()
ENDFUNCTION()
