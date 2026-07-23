#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ImageLoader : NSObject

/// Loads an image using system ImageIO / NSImage. Returns nil on failure.
+ (nullable NSImage*)imageAtURL:(NSURL*)url error:(NSError* _Nullable* _Nullable)error;

/// Pixel size of the image without fully decoding when possible.
+ (NSSize)pixelSizeOfImageAtURL:(NSURL*)url;

@end

NS_ASSUME_NONNULL_END
