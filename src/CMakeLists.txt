set(SHOWIMAGE_APP_SOURCES
  main.mm
  AppDelegate.mm
  MainWindowController.mm
  ImageCanvasView.mm
  ImageLoader.mm
  SandboxAccess.mm
)

set(SHOWIMAGE_APP_HEADERS
  AppDelegate.h
  MainWindowController.h
  ImageCanvasView.h
  ImageLoader.h
  SandboxAccess.h
)

add_executable(ShowImageApp MACOSX_BUNDLE
  ${SHOWIMAGE_APP_SOURCES}
  ${SHOWIMAGE_APP_HEADERS}
)

target_link_libraries(ShowImageApp
  PRIVATE
    showimage::core
    "-framework AppKit"
    "-framework Foundation"
    "-framework ImageIO"
    "-framework CoreGraphics"
    "-framework QuartzCore"
    "-framework UniformTypeIdentifiers"
)

target_include_directories(ShowImageApp
  PRIVATE
    "${CMAKE_CURRENT_SOURCE_DIR}"
    "${CMAKE_SOURCE_DIR}/include"
)

target_compile_options(ShowImageApp PRIVATE
  -fobjc-arc
  -Wall
  -Wextra
)

# Ensure .mm files are compiled as Objective-C++
set_source_files_properties(${SHOWIMAGE_APP_SOURCES}
  PROPERTIES
    COMPILE_FLAGS "-fobjc-arc"
    LANGUAGE OBJCXX
)
