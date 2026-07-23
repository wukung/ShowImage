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

# Copy app icon into the .app Resources folder (must be in this CMakeLists dir).
set(SHOWIMAGE_ICNS "${CMAKE_SOURCE_DIR}/resources/ShowImage.icns")
if(EXISTS "${SHOWIMAGE_ICNS}")
  add_custom_command(TARGET ShowImageApp POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E make_directory
            "$<TARGET_BUNDLE_CONTENT_DIR:ShowImageApp>/Resources"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${SHOWIMAGE_ICNS}"
            "$<TARGET_BUNDLE_CONTENT_DIR:ShowImageApp>/Resources/ShowImage.icns"
    COMMENT "Copy ShowImage.icns into app bundle"
    VERBATIM
  )
endif()
