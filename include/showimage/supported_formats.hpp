#pragma once

#include "showimage/types.hpp"

#include <string>
#include <string_view>
#include <vector>

namespace showimage {

/// Extensions commonly handled by Apple ImageIO / NSImage on modern macOS.
/// Comparison is case-insensitive and without the leading dot.
[[nodiscard]] const std::vector<std::string>& SupportedExtensions();

/// Returns true if `pathOrExtension` ends with (or is) a supported extension.
[[nodiscard]] bool IsSupportedImagePath(std::string_view pathOrExtension);

/// Lowercased extension without dot, or empty if none.
[[nodiscard]] std::string ExtensionOf(std::string_view path);

/// Human-readable summary for About / UI.
[[nodiscard]] std::string SupportedFormatsDescription();

}  // namespace showimage
