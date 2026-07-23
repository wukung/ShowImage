#include "showimage/supported_formats.hpp"

#include <algorithm>
#include <cctype>

namespace showimage {
namespace {

std::string ToLower(std::string_view input) {
  std::string out;
  out.reserve(input.size());
  for (unsigned char ch : input) {
    out.push_back(static_cast<char>(std::tolower(ch)));
  }
  return out;
}

}  // namespace

const std::vector<std::string>& SupportedExtensions() {
  // ImageIO / NSImage common set on macOS 12+.
  static const std::vector<std::string> kExts = {
      "jpg", "jpeg", "png", "gif", "tif", "tiff", "bmp", "ico",
      "heic", "heif", "webp", "jp2", "j2k", "jpf", "exr", "hdr",
  };
  return kExts;
}

std::string ExtensionOf(std::string_view path) {
  const auto slash = path.find_last_of("/\\");
  const auto base =
      (slash == std::string_view::npos) ? path : path.substr(slash + 1);
  const auto dot = base.find_last_of('.');
  if (dot == std::string_view::npos || dot + 1 >= base.size()) {
    return {};
  }
  return ToLower(base.substr(dot + 1));
}

bool IsSupportedImagePath(std::string_view pathOrExtension) {
  std::string ext = ExtensionOf(pathOrExtension);
  if (ext.empty()) {
    // Treat as bare extension (with or without leading dot).
    std::string_view view = pathOrExtension;
    if (!view.empty() && view.front() == '.') {
      view.remove_prefix(1);
    }
    ext = ToLower(view);
  }
  const auto& supported = SupportedExtensions();
  return std::find(supported.begin(), supported.end(), ext) != supported.end();
}

std::string SupportedFormatsDescription() {
  return "JPEG, PNG, GIF, TIFF, BMP, HEIC/HEIF, WebP, JPEG 2000, and other "
         "formats supported by system ImageIO.";
}

}  // namespace showimage
