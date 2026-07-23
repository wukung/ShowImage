#pragma once

#include <cstdint>
#include <string>

namespace showimage {

/// Portable path string (UTF-8). Callers convert to NSURL/NSString at the UI boundary.
using PathString = std::string;

struct ImageEntry {
  PathString path;
  std::string fileName;
};

enum class NavigateDirection : std::int8_t {
  Previous = -1,
  Next = 1,
};

}  // namespace showimage
