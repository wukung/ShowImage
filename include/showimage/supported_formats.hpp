#pragma once

// Extension allow-list aligned with system ImageIO / NSImage.
// The core does not decode images — it only filters which files enter ImageList.

#include "showimage/types.hpp"

#include <string>
#include <string_view>
#include <vector>

namespace showimage {

/// Extensions commonly handled by Apple ImageIO / NSImage on modern macOS.
/// Comparison is case-insensitive and without the leading dot.
[[nodiscard]] const std::vector<std::string>& SupportedExtensions();

/// True if `pathOrExtension` ends with (or is) a supported extension.
/// Accepts a full path or a bare extension (with or without leading '.').
[[nodiscard]] bool IsSupportedImagePath(std::string_view pathOrExtension);

/// Lowercased extension without the leading dot, or empty if none.
[[nodiscard]] std::string ExtensionOf(std::string_view path);

/// Human-readable summary for welcome screen / status / About.
[[nodiscard]] std::string SupportedFormatsDescription();

}  // namespace showimage
