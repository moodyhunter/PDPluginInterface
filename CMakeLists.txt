cmake_minimum_required(VERSION 3.20.0)

project(PDPluginInterface VERSION 1.0)

find_package(Qt6 6.2 COMPONENTS Core Gui Quick REQUIRED)

set(INTERFACE_HEADERS
    ${CMAKE_CURRENT_LIST_DIR}/include/PDPlugin/PluginInterface.hpp
    ${CMAKE_CURRENT_LIST_DIR}/include/PDPlugin/PluginBase/PDBaseTypes.hpp
)

set(FEATURE_HEADERS
)

add_library(${PROJECT_NAME} INTERFACE ${INTERFACE_HEADERS} ${FEATURE_HEADERS})
add_library(PD::${PROJECT_NAME} ALIAS ${PROJECT_NAME})

set_target_properties(${PROJECT_NAME} PROPERTIES AUTOMOC OFF AUTOUIC OFF AUTORCC OFF VERSION ${PROJECT_VERSION} SOVERSION 0)
target_link_libraries(${PROJECT_NAME} INTERFACE Qt::Core Qt::Gui Qt::Quick)

include(GNUInstallDirs)
set(INSTALLATION_PACKAGE_DIR ${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME})

target_include_directories(${PROJECT_NAME} INTERFACE
    "$<BUILD_INTERFACE:${CMAKE_CURRENT_LIST_DIR}/include>"
    "$<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>"
)

include(CMakePackageConfigHelpers)

write_basic_package_version_file(
    ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake
    VERSION ${PROJECT_VERSION}
    COMPATIBILITY SameMajorVersion
    ARCH_INDEPENDENT)

configure_package_config_file(${CMAKE_CURRENT_LIST_DIR}/cmake/PDPluginInterfaceConfig.cmake.in
    ${CMAKE_CURRENT_BINARY_DIR}/PDPluginInterfaceConfig.cmake
    INSTALL_DESTINATION ${INSTALLATION_PACKAGE_DIR}
)

install(TARGETS ${PROJECT_NAME}
    EXPORT ${PROJECT_NAME}Targets
)

install(EXPORT ${PROJECT_NAME}Targets
    NAMESPACE PD::
    COMPONENT "development"
    EXCLUDE_FROM_ALL
    DESTINATION ${INSTALLATION_PACKAGE_DIR}
)

install(FILES
    ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Config.cmake
    ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake
    COMPONENT "development"
    EXCLUDE_FROM_ALL
    DESTINATION ${INSTALLATION_PACKAGE_DIR})

install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/cmake/${PROJECT_NAME}Macros.cmake
    COMPONENT "development"
    EXCLUDE_FROM_ALL
    DESTINATION ${INSTALLATION_PACKAGE_DIR})

install(DIRECTORY ${CMAKE_CURRENT_LIST_DIR}/include/
    COMPONENT "development"
    EXCLUDE_FROM_ALL
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})

export(EXPORT ${PROJECT_NAME}Targets
    FILE "${CMAKE_CURRENT_BINARY_DIR}/cmake/${PROJECT_NAME}Targets.cmake"
    NAMESPACE PD::
)

include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/${PROJECT_NAME}Macros.cmake)
