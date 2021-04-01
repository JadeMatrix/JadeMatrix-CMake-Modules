#[=======================================================================[.rst:
JadeMatrix-CMake-Modules/FindScripts
--------------------------------------

This module adds a directory containing custom CMake Find scripts to the
``CMAKE_MODULE_PATH``.
#]=======================================================================]

CMAKE_MINIMUM_REQUIRED( VERSION 3.3 FATAL_ERROR #[[
    Requiring 3.3+:
        IF( ... IN_LIST ... )
]] )

IF(
       NOT "${CMAKE_CURRENT_LIST_DIR}/Find/" IN_LIST CMAKE_MODULE_PATH
    OR NOT "${CMAKE_CURRENT_LIST_DIR}/Find"  IN_LIST CMAKE_MODULE_PATH
)
    LIST( APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/Find/" )
ENDIF()
