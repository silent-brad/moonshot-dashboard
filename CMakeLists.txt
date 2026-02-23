# Lua RTOS for CrowPanel ESP32-S3 5-inch Display
# ESP-IDF v5.x Project

cmake_minimum_required(VERSION 3.16)

# Set version to avoid git describe errors when IDF_PATH is in nix store
set(PROJECT_VER "1.0.0")

set(EXTRA_COMPONENT_DIRS 
    ${CMAKE_CURRENT_SOURCE_DIR}/components
)

include($ENV{IDF_PATH}/tools/cmake/project.cmake)
project(moonshot_display VERSION ${PROJECT_VER})
