#include "showimage/image_list.hpp"

#include "showimage/supported_formats.hpp"

#include <algorithm>
#include <filesystem>
#include <system_error>

namespace showimage {
namespace fs = std::filesystem;

namespace {

std::string FileNameFromPath(const PathString& path) {
  const fs::path p(path);
  return p.filename().string();
}

// Parent of a file path; falls back to "./" if the path has no parent.
PathString ParentDirectory(const PathString& filePath) {
  const fs::path p(filePath);
  return p.has_parent_path() ? p.parent_path().string() : PathString{"./"};
}

}  // namespace

void ImageList::SetSingleFile(const PathString& filePath) {
  // Single-file mode: prev/next only works after a later directory scan.
  entries_.clear();
  directory_ = ParentDirectory(filePath);
  index_ = 0;
  if (filePath.empty()) {
    return;
  }
  entries_.push_back(ImageEntry{filePath, FileNameFromPath(filePath)});
}

std::size_t ImageList::ScanDirectory(const PathString& directory) {
  entries_.clear();
  directory_ = directory;
  index_ = 0;

  std::error_code ec;
  const fs::path dir(directory);
  if (!fs::is_directory(dir, ec)) {
    return 0;
  }

  // Non-recursive listing; skip entries we cannot access (sandbox / permissions).
  for (const auto& entry : fs::directory_iterator(
           dir, fs::directory_options::skip_permission_denied, ec)) {
    if (ec) {
      break;
    }
    if (!entry.is_regular_file(ec)) {
      continue;
    }
    const auto path = entry.path().string();
    if (!IsSupportedImagePath(path)) {
      continue;
    }
    entries_.push_back(ImageEntry{path, entry.path().filename().string()});
  }

  // Byte-order sort (not Finder natural sort) — simple and locale-independent.
  std::sort(entries_.begin(), entries_.end(),
            [](const ImageEntry& a, const ImageEntry& b) {
              return a.fileName < b.fileName;
            });

  return entries_.size();
}

std::size_t ImageList::ScanDirectorySelecting(const PathString& directory,
                                              const PathString& preferredFile) {
  const std::size_t count = ScanDirectory(directory);
  if (count == 0) {
    return 0;
  }

  // Canonicalize so "./a.jpg" and "/abs/a.jpg" still match when possible.
  std::error_code ec;
  const fs::path preferred = fs::weakly_canonical(preferredFile, ec);
  const std::string preferredStr =
      ec ? preferredFile : preferred.string();

  for (std::size_t i = 0; i < entries_.size(); ++i) {
    const fs::path candidate = fs::weakly_canonical(entries_[i].path, ec);
    const std::string candidateStr =
        ec ? entries_[i].path : candidate.string();
    if (candidateStr == preferredStr || entries_[i].path == preferredFile) {
      index_ = i;
      break;
    }
  }
  return count;
}

std::optional<ImageEntry> ImageList::Current() const {
  if (entries_.empty() || index_ >= entries_.size()) {
    return std::nullopt;
  }
  return entries_[index_];
}

bool ImageList::Navigate(NavigateDirection direction) {
  if (entries_.size() <= 1) {
    return false;
  }
  // Wrap-around: (i + d) mod n, handling negative via (x % n + n) % n.
  const auto n = static_cast<std::ptrdiff_t>(entries_.size());
  auto next = static_cast<std::ptrdiff_t>(index_) +
              static_cast<std::ptrdiff_t>(direction);
  next = (next % n + n) % n;
  index_ = static_cast<std::size_t>(next);
  return true;
}

bool ImageList::SetIndex(std::size_t index) {
  if (index >= entries_.size()) {
    return false;
  }
  index_ = index;
  return true;
}

}  // namespace showimage
