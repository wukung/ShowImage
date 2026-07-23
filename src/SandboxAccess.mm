#import "SandboxAccess.h"

@interface SandboxAccess ()
@property(nonatomic, strong, nullable) NSURL* directoryURL;
@property(nonatomic, strong, nullable) NSURL* fileURL;
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
  // Open panel URLs often already grant access; still track for cleanup when started.
  if (started) {
    [self.scopedURLs addObject:url];
  }

  NSNumber* isDir = nil;
  BOOL ok = [url getResourceValue:&isDir forKey:NSURLIsDirectoryKey error:nil];
  if (ok && isDir.boolValue) {
    self.directoryURL = url;
  } else {
    self.fileURL = url;
    // Remember parent for display; sandbox may still block listing siblings.
    self.directoryURL = url.URLByDeletingLastPathComponent;
  }
  return YES;
}

@end
