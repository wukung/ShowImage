add_library(showimage_core STATIC
  supported_formats.cpp
  image_list.cpp
)

add_library(showimage::core ALIAS showimage_core)

target_include_directories(showimage_core
  PUBLIC
    "${CMAKE_SOURCE_DIR}/include"
)

target_compile_features(showimage_core PUBLIC cxx_std_17)

# Quiet unused-result noise on AppleClang when building as library
if(APPLE)
  target_compile_options(showimage_core PRIVATE
    -Wall
    -Wextra
    -Wpedantic
  )
endif()
