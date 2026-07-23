#import <Cocoa/Cocoa.h>
#import "ImageCanvasView.h"

NS_ASSUME_NONNULL_BEGIN

/// Main window: welcome overlay, image canvas, status bar, open/navigate/zoom.
/// Owns the C++ ImageList (new in init / delete in dealloc) and SandboxAccess.
@interface MainWindowController : NSWindowController <NSWindowDelegate, ImageCanvasViewDelegate>

/// Open file or directory URLs from Open panels, Dock, or Finder.
- (void)openURLs:(NSArray<NSURL*>*)urls;

- (IBAction)openDocument:(nullable id)sender;
- (IBAction)openFolder:(nullable id)sender;
- (IBAction)previousImage:(nullable id)sender;
- (IBAction)nextImage:(nullable id)sender;
- (IBAction)zoomIn:(nullable id)sender;
- (IBAction)zoomOut:(nullable id)sender;
- (IBAction)zoomActualSize:(nullable id)sender;
- (IBAction)zoomToFit:(nullable id)sender;

@end

NS_ASSUME_NONNULL_END
