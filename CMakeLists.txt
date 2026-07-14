cmake_minimum_required(VERSION 3.16)
project(BYGRecursiveTokenizer VERSION 4.6.0 LANGUAGES CXX)

add_executable(byg src/byg.cpp)
target_compile_features(byg PRIVATE cxx_std_17)

add_library(byg_header INTERFACE)
target_include_directories(byg_header INTERFACE ${CMAKE_CURRENT_SOURCE_DIR}/include)
target_compile_features(byg_header INTERFACE cxx_std_17)

install(TARGETS byg RUNTIME DESTINATION bin)
install(DIRECTORY include/ DESTINATION include)
install(FILES
  CLI_JSON_SCHEMA.json
  COMPATIBILITY_MATRIX.json
  RELEASE_MANIFEST.json
  RELEASE_CANDIDATE_CHECKLIST.md
  INSTALL_LAYOUT.md
  API_ERROR_CONTRACT.json
  BUILD_REPRODUCIBILITY.json
  FILE_WRAPPER_CONTRACT.md
  DESTINATION share/byg
)
