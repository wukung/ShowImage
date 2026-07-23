#import "SandboxAccess.h"

// App Sandbox: only user-selected URLs (Open panel / Finder) may be read.
// We start security-scoped access and stop it when the selection changes.

@interface SandboxAccess ()
@property(nonatomic, strong, nullable) NSURL* directoryURL;
@property(nonatomic, strong, nullable) NSURL* fileURL;
/// URLs for which we successfully called startAccessingSecurityScopedResource.
@property(nonatomic, strong) NSMutableArray<NSURL*>* scopedURLs;
@end

@implementation SandboxAccess

- (instancetype)init {
  self = [super init];
  if (self) {
    _scopedURLs = [NSMutableArray array];
  }
  return self;
}

- (void)dealloc {
  [self stopAll];
}

- (void)stopAll {
  // Always pair startAccessing with stopAccessing for tracked URLs.
  for (NSURL* url in self.scopedURLs) {
    [url stopAccessingSecurityScopedResource];
  }
  [self.scopedURLs removeAllObjects];
  self.directoryURL = nil;
  self.fileURL = nil;
}

- (BOOL)startAccessingURL:(NSURL*)url {
  if (!url) {
    return NO;
  }

  BOOL started = [url startAccessingSecurityScopedResource];
  // Open panel URLs often already grant access (started == NO); only track
  // URLs where we must call stop later.
  if (started) {
    [self.scopedURLs addObject:url];
  }

  NSNumber* isDir = nil;
  BOOL ok = [url getResourceValue:&isDir forKey:NSURLIsDirectoryKey error:nil];
  if (ok && isDir.boolValue) {
    self.directoryURL = url;
  } else {
    self.fileURL = url;
    // Parent path for UI context only — listing siblings still needs folder scope.
    self.directoryURL = url.URLByDeletingLastPathComponent;
  }
  // YES means we recorded the URL; not a guarantee of unrestricted FS access.
  return YES;
}

@end
