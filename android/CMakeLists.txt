cmake_minimum_required(VERSION 3.4.1)

project(sentencepiece_lib VERSION 0.1 LANGUAGES C CXX)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR})
add_subdirectory("../ios/Classes" ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/sentencepiece)
