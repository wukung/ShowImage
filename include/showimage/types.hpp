#pragma once

// Shared portable types for the C++ core. No Objective-C types here — the UI
// layer converts PathString to NSURL/NSString at the boundary.

#include <cstdint>
#include <string>

namespace showimage {

/// Absolute or relative filesystem path as UTF-8.
/// Callers must convert to NSURL/NSString only in ObjC++ UI code.
using PathString = std::string;

/// One image file in a browsable list (path + display name).
struct ImageEntry {
  PathString path;       // full path used for loading
  std::string fileName;  // basename for status / sort
};

/// Direction for Previous/Next; values are used as index deltas.
enum class NavigateDirection : std::int8_t {
  Previous = -1,
  Next = 1,
};

}  // namespace showimage
