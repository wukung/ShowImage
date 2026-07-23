#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Tracks security-scoped URLs required by App Sandbox for folder browsing.
@interface SandboxAccess : NSObject

- (void)stopAll;

/// Start access for a user-selected URL (file or directory). Returns YES if active.
- (BOOL)startAccessingURL:(NSURL*)url;

/// Currently accessed directory URL, if any.
@property(nonatomic, readonly, nullable) NSURL* directoryURL;

/// Currently accessed file URL, if any.
@property(nonatomic, readonly, nullable) NSURL* fileURL;

@end

NS_ASSUME_NONNULL_END
