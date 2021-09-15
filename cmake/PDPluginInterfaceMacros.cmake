# So high, so modern, so "cmake_path()"
cmake_minimum_required(VERSION 3.20.0)

option(PD_STATIC_PLUGINS "Create Static Plugins")

if(NOT TARGET _PD_AllPlugins)
    add_library(_PD_AllPlugins INTERFACE)
    add_library(PD::AllPlugins ALIAS _PD_AllPlugins)
    message(STATUS "Added PD Plugins Meta Target")
endif()

function(pd_add_plugin TARGET_NAME)
    set(Stable_PluginInterface_VERSION 1)
    set(options NO_INSTALL STATIC DEV_INTERFACE DEBUGGING_EXECUTABLE)
    set(oneValueArgs INSTALL_PREFIX_LINUX INSTALL_PREFIX_WINDOWS INSTALL_PREFIX_MACOS CLASS_NAME INTERFACE_VERSION)
    set(multiValueArgs EXTRA_DEPENDENCY_DIRS_WINDOWS SOURCES QML_FILES)
    cmake_parse_arguments(PDPLUGIN "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if(DEFINED PDPLUGIN_KEYWORDS_MISSING_VALUES)
        message(FATAL_ERROR "Unknown argument(s) ${PDPLUGIN_KEYWORDS_MISSING_VALUES}")
    endif()

    # ====================================== BEGIN PARSING ARGUMENTS
    if(NOT DEFINED PDPLUGIN_NO_INSTALL)
        set(PDPLUGIN_NO_INSTALL FALSE)
    endif()

    if((NOT DEFINED PDPLUGIN_INSTALL_PREFIX_LINUX) OR (PDPLUGIN_INSTALL_PREFIX_LINUX STREQUAL ""))
        set(PDPLUGIN_INSTALL_PREFIX_LINUX "lib/PersonalDashboard/plugins")
    endif()

    if((NOT DEFINED PDPLUGIN_INSTALL_PREFIX_WINDOWS) OR (PDPLUGIN_INSTALL_PREFIX_WINDOWS STREQUAL ""))
        set(PDPLUGIN_INSTALL_PREFIX_WINDOWS "plugins")
    endif()

    if((NOT DEFINED PDPLUGIN_INSTALL_PREFIX_MACOS) OR (PDPLUGIN_INSTALL_PREFIX_MACOS STREQUAL ""))
        set(PDPLUGIN_INSTALL_PREFIX_MACOS "plugins")
    endif()

    if(PDPLUGIN_STATIC OR PD_STATIC_PLUGINS)
        set(PDPLUGIN_STATIC ON)
        set(PDPLUGIN_NO_INSTALL ON)
        if((NOT DEFINED PDPLUGIN_CLASS_NAME) OR (PDPLUGIN_CLASS_NAME STREQUAL ""))
            message(FATAL_ERROR "A static plugin must provide its main plugin class name.")
        endif()
    endif()

    if(PDPLUGIN_DEV_INTERFACE)
        if(DEFINED PDPLUGIN_INTERFACE_VERSION)
            message(FATAL_ERROR "Cannot specify INTERFACE_VERSION and DEV_INTERFACE at the same time.")
        endif()

        math(EXPR DEV_VERSION "${Stable_PluginInterface_VERSION} + 1")
        set(PDPLUGIN_INTERFACE_VERSION ${DEV_VERSION})
        message(STATUS "Use Interface version ${PDPLUGIN_INTERFACE_VERSION} (dev)")
    else()
        if(NOT DEFINED PDPLUGIN_INTERFACE_VERSION)
            set(PDPLUGIN_INTERFACE_VERSION ${Stable_PluginInterface_VERSION})
        endif()
        message(STATUS "Use Interface version ${PDPLUGIN_INTERFACE_VERSION}")
    endif()

    # ====================================== END PARSING ARGUMENTS

    if(NOT PDPluginInterface_UseAsLib)
        get_filename_component(PDPluginInterface_Prefix "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../include/" ABSOLUTE)
    else()
        get_target_property(PDPluginInterface_Prefix PD::PDPluginInterface INTERFACE_INCLUDE_DIRECTORIES)
    endif()

    if(PDPLUGIN_STATIC)
        add_library(${TARGET_NAME} STATIC)
        target_link_libraries(_PD_AllPlugins INTERFACE ${TARGET_NAME})
        target_compile_definitions(${TARGET_NAME} PRIVATE "QT_STATICPLUGIN=1")
        message(STATUS "Generating static plugin importing source code for ${TARGET_NAME}")

        get_target_property(OUT ${TARGET_NAME} BINARY_DIR)
        set(IMPORT_SRC "${OUT}/${TARGET_NAME}_PD_static_plugin_import.cpp")

        # Write the file header
        file(WRITE ${IMPORT_SRC} [[
// PD Static Plugin Import File
// File Generated via CMake script during configure time.
// Please rerun CMake to update this file, this file will be overwrite at each CMake run.
#include <QtPlugin>
]]
            )
        file(APPEND ${IMPORT_SRC} "Q_IMPORT_PLUGIN(${PDPLUGIN_CLASS_NAME});")
        message("Generated at: ${IMPORT_SRC}")
        target_sources(${TARGET_NAME} INTERFACE ${IMPORT_SRC})
        set_target_properties(${TARGET_NAME} PROPERTIES CXX_VISIBILITY_PRESET hidden)
    else()
        add_library(${TARGET_NAME} SHARED)
    endif()

    find_package(Qt6 COMPONENTS Core Gui Quick REQUIRED)
    target_link_libraries(${TARGET_NAME} PRIVATE Qt::Core Qt::Gui Qt::Quick PD::PDPluginInterface)
    set_target_properties(${TARGET_NAME} PROPERTIES AUTOMOC ON)
    set_property(TARGET ${TARGET_NAME} APPEND PROPERTY AUTOMOC_MACRO_NAMES "PD_PLUGIN")
    target_compile_definitions(${TARGET_NAME} PRIVATE -DPLUGIN_INTERFACE_VERSION=${PDPLUGIN_INTERFACE_VERSION})
    target_compile_definitions(${TARGET_NAME} PRIVATE -DPDPLUGIN_QML_URI="PDPlugins.${TARGET_NAME}")
    target_compile_definitions(${TARGET_NAME} PRIVATE -DPDPLUGIN_QML_IMPORT_PATH="/PDPlugins/${TARGET_NAME}/")

    qt_add_qml_module(${TARGET_NAME}
        URI "PDPlugins.${TARGET_NAME}"
        VERSION ${PDPLUGIN_INTERFACE_VERSION}.0
        RESOURCE_PREFIX "/"
        NO_PLUGIN
        QML_FILES
            ${PDPLUGIN_QML_FILES}
        SOURCES
            ${PDPLUGIN_SOURCES}
    )

    if(CMAKE_CXX_COMPILER_ID EQUAL Clang OR CMAKE_COMPILER_IS_GNUCC OR CMAKE_COMPILER_IS_GNUCXX)
        if(UNIX AND NOT APPLE)
            target_link_libraries(${TARGET_NAME} PRIVATE "-Wl,-z,defs")
        endif()
    endif()

    if(PDPLUGIN_DEBUGGING_EXECUTABLE)
        message(STATUS "Adding debugging executable.")
        set_target_properties(${TARGET_NAME} PROPERTIES ENABLE_EXPORTS 1)
        get_target_property(OUT ${TARGET_NAME} BINARY_DIR)
        set(EXEC_SOURCE "${OUT}/${TARGET_NAME}_exec.cpp")
        file(WRITE ${EXEC_SOURCE} [[
// PD Plugin Debugging Executable Helper Launcher
// File Generated via CMake script during configure time.
// Please rerun CMake to update this file, this file will be overwrite at each CMake run.
extern int plugin_main(int argc, char *argv[]);
int main(int argc, char *argv[])
{
    return plugin_main(argc, argv);
}
]])
        add_executable(${TARGET_NAME}_exec ${EXEC_SOURCE})
        target_link_libraries(${TARGET_NAME}_exec PRIVATE ${TARGET_NAME})
    endif()

    if(APPLE)
        add_custom_command(TARGET ${TARGET_NAME}
            POST_BUILD
            COMMAND
            ${CMAKE_INSTALL_NAME_TOOL} -add_rpath "@executable_path/../Frameworks/" $<TARGET_FILE:${TARGET_NAME}>)
    endif()

    if(NOT PDPLUGIN_NO_INSTALL)
        cmake_policy(SET CMP0087 NEW)
        if(${CMAKE_SYSTEM_NAME} STREQUAL "Linux")
            install(TARGETS ${TARGET_NAME} LIBRARY DESTINATION ${PDPLUGIN_INSTALL_PREFIX_LINUX})
        elseif(WIN32)
            install(TARGETS ${TARGET_NAME} RUNTIME DESTINATION ${PDPLUGIN_INSTALL_PREFIX_WINDOWS})
            install(CODE "
set(EXTRA_DIRS \"${PDPLUGIN_EXTRA_DEPENDENCY_DIRS_WINDOWS}\")
list(APPEND EXTRA_DIRS \"$<TARGET_PROPERTY:${TARGET_NAME},BINARY_DIR>\")
set(PLUGIN_INSTALL_PREFIX \"${CMAKE_INSTALL_PREFIX}/${PDPLUGIN_INSTALL_PREFIX_WINDOWS}/libs\")
set(TARGET_NAME ${TARGET_NAME})
set(TARGET_FILE \"$<TARGET_FILE:${TARGET_NAME}>\")
")

            install(CODE [[
file(GET_RUNTIME_DEPENDENCIES
    LIBRARIES ${TARGET_FILE}
    RESOLVED_DEPENDENCIES_VAR "dependencies"
    UNRESOLVED_DEPENDENCIES_VAR "un_depenendcies_unused"
    DIRECTORIES ${EXTRA_DIRS}
    )
foreach(dll ${dependencies})
    foreach(dir ${EXTRA_DIRS})
        cmake_path(IS_PREFIX dir "${dll}" NORMALIZE FOUND)
        if(FOUND)
            message(STATUS "${TARGET_NAME}: Found dependency: '${dll}'.")
            file(COPY ${dll} DESTINATION ${PLUGIN_INSTALL_PREFIX})
            break()
        endif()
    endforeach()
endforeach()
]])
        elseif(APPLE)
            install(TARGETS ${TARGET_NAME} LIBRARY DESTINATION ${PDPLUGIN_INSTALL_PREFIX_MACOS})
        else()
            message(FATAL_ERROR "Installation on this platform is not supported yet.")
        endif()
    endif()

    message(STATUS "==========================================================")
    message(STATUS "PD Plugin ${TARGET_NAME}")
    message(STATUS "   API Version: ${PDPLUGIN_INTERFACE_VERSION}")
    message(STATUS "        Static: ${PDPLUGIN_STATIC}")
    message(STATUS "  Debug Helper: ${PDPLUGIN_DEBUGGING_EXECUTABLE}")
    message(STATUS "    No Install: ${PDPLUGIN_NO_INSTALL}")
    message(STATUS " Global Prefix: ${CMAKE_INSTALL_PREFIX}")
    message(STATUS "  Linux Prefix: ${PDPLUGIN_INSTALL_PREFIX_LINUX}")
    message(STATUS "  macOS Prefix: ${PDPLUGIN_INSTALL_PREFIX_MACOS}")
    message(STATUS "Windows Prefix: ${PDPLUGIN_INSTALL_PREFIX_WINDOWS}")
    message(STATUS "==========================================================")
    message("")
endfunction()
