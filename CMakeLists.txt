CMAKE_MINIMUM_REQUIRED( VERSION 3.11 FATAL_ERROR #[[
    Requiring 3.11+:
        WRITE_BASIC_PACKAGE_VERSION_FILE( ... SameMinorVersion ... )
]] )

PROJECT(
    "JadeMatrix's CMake Modules"
    VERSION 1.8
    LANGUAGES NONE
)

INCLUDE( GNUInstallDirs )

INSTALL(
    FILES "JadeMatrix-CMake-ModulesConfig.cmake"
    DESTINATION "${CMAKE_INSTALL_DATAROOTDIR}/JadeMatrix-CMake-Modules/"
)
INSTALL(
    DIRECTORY "CMakeModules"
    DESTINATION "${CMAKE_INSTALL_DATAROOTDIR}/JadeMatrix-CMake-Modules/"
)

CONFIGURE_FILE(
    "${PROJECT_SOURCE_DIR}/JadeMatrix-CMake-ModulesConfigVersion.cmake.in"
    "${PROJECT_BINARY_DIR}/JadeMatrix-CMake-ModulesConfigVersion.cmake"
    @ONLY
)
INSTALL(
    FILES "${PROJECT_BINARY_DIR}/JadeMatrix-CMake-ModulesConfigVersion.cmake"
    DESTINATION "${CMAKE_INSTALL_DATAROOTDIR}/JadeMatrix-CMake-Modules/"
)
