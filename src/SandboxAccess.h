#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Tracks security-scoped URLs required by App Sandbox for user-selected files
/// and folders. Call stopAll when replacing the current selection or on dealloc.
///
/// Note: startAccessingURL: returns YES for non-nil URLs even when
/// startAccessingSecurityScopedResource returns NO (powerbox may already grant
/// access). Parent directory after a file open may still not be listable.
@interface SandboxAccess : NSObject

/// Release every tracked security-scoped resource.
- (void)stopAll;

/// Begin access for a user-selected file or directory URL.
/// Returns YES if url is non-nil (does not always mean scope was newly started).
- (BOOL)startAccessingURL:(NSURL*)url;

/// Last directory associated with access (folder open, or parent of a file).
@property(nonatomic, readonly, nullable) NSURL* directoryURL;

/// Last file URL opened, if the selection was a file.
@property(nonatomic, readonly, nullable) NSURL* fileURL;

@end

NS_ASSUME_NONNULL_END
