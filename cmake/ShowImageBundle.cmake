# Configures the macOS .app bundle: Info.plist, resources, entitlements, rpath.

function(showimage_configure_app_bundle target)
  set(PRODUCT_NAME "ShowImage")
  set(BUNDLE_IDENTIFIER "com.example.ShowImage")
  set(COPYRIGHT "Copyright © 2026")
  set(MARKETING_VERSION "${PROJECT_VERSION}")
  set(CURRENT_PROJECT_VERSION "1")
  # Exposed to Info.plist.in via @CMAKE_OSX_DEPLOYMENT_TARGET@
  set(CMAKE_OSX_DEPLOYMENT_TARGET "${CMAKE_OSX_DEPLOYMENT_TARGET}")

  set(INFO_PLIST_IN "${CMAKE_SOURCE_DIR}/resources/Info.plist.in")
  set(INFO_PLIST_OUT "${CMAKE_BINARY_DIR}/Info.plist")
  configure_file("${INFO_PLIST_IN}" "${INFO_PLIST_OUT}" @ONLY)

  set_target_properties(${target} PROPERTIES
    MACOSX_BUNDLE TRUE
    MACOSX_BUNDLE_INFO_PLIST "${INFO_PLIST_OUT}"
    MACOSX_BUNDLE_BUNDLE_NAME "${PRODUCT_NAME}"
    MACOSX_BUNDLE_BUNDLE_VERSION "${CURRENT_PROJECT_VERSION}"
    MACOSX_BUNDLE_SHORT_VERSION_STRING "${MARKETING_VERSION}"
    MACOSX_BUNDLE_GUI_IDENTIFIER "${BUNDLE_IDENTIFIER}"
    OUTPUT_NAME "${PRODUCT_NAME}"
    XCODE_ATTRIBUTE_PRODUCT_BUNDLE_IDENTIFIER "${BUNDLE_IDENTIFIER}"
    XCODE_ATTRIBUTE_MARKETING_VERSION "${MARKETING_VERSION}"
    XCODE_ATTRIBUTE_CURRENT_PROJECT_VERSION "${CURRENT_PROJECT_VERSION}"
    XCODE_ATTRIBUTE_MACOSX_DEPLOYMENT_TARGET "${CMAKE_OSX_DEPLOYMENT_TARGET}"
    XCODE_ATTRIBUTE_CODE_SIGN_STYLE "Automatic"
    XCODE_ATTRIBUTE_ENABLE_HARDENED_RUNTIME YES
    XCODE_ATTRIBUTE_CLANG_ENABLE_OBJC_ARC YES
  )

  if(SHOWIMAGE_ENABLE_SANDBOX)
    set(ENTITLEMENTS "${CMAKE_SOURCE_DIR}/resources/ShowImage.entitlements")
    set_target_properties(${target} PROPERTIES
      XCODE_ATTRIBUTE_CODE_SIGN_ENTITLEMENTS "${ENTITLEMENTS}"
    )
    # For Ninja/Makefile generators, attach entitlements at link/sign time when codesign is used.
    target_sources(${target} PRIVATE "${ENTITLEMENTS}")
  endif()

  # App icon metadata (actual copy is in src/CMakeLists.txt — same dir as target).
  set(RESOURCES_DIR "${CMAKE_SOURCE_DIR}/resources")
  set(APP_ICNS "${RESOURCES_DIR}/ShowImage.icns")
  if(EXISTS "${APP_ICNS}")
    set_target_properties(${target} PROPERTIES
      MACOSX_BUNDLE_ICON_FILE "ShowImage"
    )
  endif()
endfunction()
