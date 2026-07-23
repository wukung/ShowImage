#pragma once

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

  /// Replace contents with a single file (no siblings).
  void SetSingleFile(const PathString& filePath);

  /// Replace contents by scanning `directory` for supported images (sorted by name).
  /// Returns number of images found.
  std::size_t ScanDirectory(const PathString& directory);

  /// Scan `directory` and select `preferredFile` if present; otherwise first image.
  std::size_t ScanDirectorySelecting(const PathString& directory,
                                     const PathString& preferredFile);

  [[nodiscard]] bool Empty() const noexcept { return entries_.empty(); }
  [[nodiscard]] std::size_t Size() const noexcept { return entries_.size(); }
  [[nodiscard]] std::size_t Index() const noexcept { return index_; }

  [[nodiscard]] std::optional<ImageEntry> Current() const;
  [[nodiscard]] const PathString& Directory() const noexcept { return directory_; }

  /// Move by one step; wraps around. Returns false if empty or only one image.
  bool Navigate(NavigateDirection direction);

  /// Jump to absolute index if in range.
  bool SetIndex(std::size_t index);

  [[nodiscard]] const std::vector<ImageEntry>& Entries() const noexcept {
    return entries_;
  }

 private:
  PathString directory_;
  std::vector<ImageEntry> entries_;
  std::size_t index_ = 0;
};

}  // namespace showimage
