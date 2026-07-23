#import "ImageLoader.h"

#import <ImageIO/ImageIO.h>

// Thin wrapper around NSImage + ImageIO. Decoding stays out of the C++ core
// so showimage_core never links AppKit.

@implementation ImageLoader

+ (NSImage*)imageAtURL:(NSURL*)url error:(NSError* _Nullable* _Nullable)error {
  if (!url.isFileURL) {
    if (error) {
      *error = [NSError errorWithDomain:@"ShowImage"
                                   code:1
                               userInfo:@{
                                 NSLocalizedDescriptionKey : @"Only file URLs are supported."
                               }];
    }
    return nil;
  }

  // NSImage uses ImageIO under the hood for common formats (JPEG/PNG/HEIC/WebP/…).
  NSImage* image = [[NSImage alloc] initWithContentsOfURL:url];
  if (!image) {
    if (error) {
      *error = [NSError errorWithDomain:@"ShowImage"
                                   code:2
                               userInfo:@{
                                 NSLocalizedDescriptionKey :
                                     [NSString stringWithFormat:@"Failed to load image: %@",
                                                                url.lastPathComponent]
                               }];
    }
    return nil;
  }

  // Default NSImage.size may be in points; prefer true pixel size for zoom %
  // and "actual size" framing.
  const NSSize pixels = [self pixelSizeOfImageAtURL:url];
  if (pixels.width > 0 && pixels.height > 0) {
    image.size = pixels;
  }
  return image;
}

+ (NSSize)pixelSizeOfImageAtURL:(NSURL*)url {
  // Properties-only query — avoids a second full bitmap decode when possible.
  CGImageSourceRef source =
      CGImageSourceCreateWithURL((__bridge CFURLRef)url, nullptr);
  if (!source) {
    return NSZeroSize;
  }

  CFDictionaryRef props = CGImageSourceCopyPropertiesAtIndex(source, 0, nullptr);
  CFRelease(source);
  if (!props) {
    return NSZeroSize;
  }

  NSDictionary* dict = CFBridgingRelease(props);
  NSNumber* width = dict[(id)kCGImagePropertyPixelWidth];
  NSNumber* height = dict[(id)kCGImagePropertyPixelHeight];
  if (!width || !height) {
    return NSZeroSize;
  }
  return NSMakeSize(width.doubleValue, height.doubleValue);
}

@end
