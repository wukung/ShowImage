#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@class ImageCanvasView;

/// Keyboard / zoom notifications from the canvas to the window controller.
@protocol ImageCanvasViewDelegate <NSObject>
@optional
- (void)imageCanvasViewRequestPrevious:(ImageCanvasView*)view;
- (void)imageCanvasViewRequestNext:(ImageCanvasView*)view;
- (void)imageCanvasViewDidChangeZoom:(ImageCanvasView*)view;
@end

/// Scrollable image canvas: centered when smaller than the view, scrollers when
/// larger, single frame-based zoom system (no NSScrollView magnification).
///
/// Sticky Fit to View: when fitToView is YES, window resize re-fits the image
/// until the user zooms manually (in/out, actual size, pinch, ⌘+scroll).
@interface ImageCanvasView : NSView

@property(nonatomic, weak, nullable) id<ImageCanvasViewDelegate> delegate;
@property(nonatomic, strong, nullable) NSImage* image;
@property(nonatomic, assign, readonly) CGFloat zoomFactor;
/// YES while sticky Zoom to Fit is active (recomputed on canvas resize).
@property(nonatomic, assign, readonly, getter=isFitToView) BOOL fitToView;

- (void)setImage:(nullable NSImage*)image fitToView:(BOOL)fitToView;
- (void)zoomIn;
- (void)zoomOut;
- (void)zoomActualSize;
- (void)zoomToFit;
/// Multiply current zoom by delta (trackpad-style cumulative factor).
- (void)magnifyBy:(CGFloat)delta;

@end

NS_ASSUME_NONNULL_END
