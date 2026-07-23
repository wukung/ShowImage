#pragma once

// Ordered playlist of images (single file or directory scan).
// Pure C++: no AppKit. The UI owns security-scoped access and decoding.

#include "showimage/types.hpp"

#include <cstddef>
#include <optional>
#include <string>
#include <vector>

namespace showimage {

/// Ordered list of images in a directory (or a single file).
/// Pure C++: no Objective-C; UI layer owns security-scoped access.
class ImageList {
 public:
  ImageList() = default;

  /// Replace contents with a single file (no sibling scan).
  void SetSingleFile(const PathString& filePath);

  /// Scan `directory` for supported images (sorted by fileName, byte order).
  /// Returns the number of images found (0 if not a directory or empty).
  std::size_t ScanDirectory(const PathString& directory);

  /// Scan then select `preferredFile` if present; otherwise keep index 0.
  std::size_t ScanDirectorySelecting(const PathString& directory,
                                     const PathString& preferredFile);

  [[nodiscard]] bool Empty() const noexcept { return entries_.empty(); }
  [[nodiscard]] std::size_t Size() const noexcept { return entries_.size(); }
  [[nodiscard]] std::size_t Index() const noexcept { return index_; }

  [[nodiscard]] std::optional<ImageEntry> Current() const;
  [[nodiscard]] const PathString& Directory() const noexcept { return directory_; }

  /// Move by one step with wrap-around. False if empty or only one image.
  bool Navigate(NavigateDirection direction);

  /// Jump to absolute index if in range.
  bool SetIndex(std::size_t index);

  [[nodiscard]] const std::vector<ImageEntry>& Entries() const noexcept {
    return entries_;
  }

 private:
  PathString directory_;              // parent folder of the list
  std::vector<ImageEntry> entries_;  // sorted playlist
  std::size_t index_ = 0;            // current image
};

}  // namespace showimage
