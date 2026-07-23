#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Loads images via system ImageIO / NSImage (no third-party decoders).
/// Synchronous and intended for the main thread in v1.
@interface ImageLoader : NSObject

/// Fully load an image from a file URL. Sets NSImage.size to pixel size when known.
/// Returns nil on failure and optionally fills *error.
+ (nullable NSImage*)imageAtURL:(NSURL*)url error:(NSError* _Nullable* _Nullable)error;

/// Pixel dimensions from ImageIO properties without a full decode when possible.
+ (NSSize)pixelSizeOfImageAtURL:(NSURL*)url;

@end

NS_ASSUME_NONNULL_END
