#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@class ImageCanvasView;

@protocol ImageCanvasViewDelegate <NSObject>
@optional
- (void)imageCanvasViewRequestPrevious:(ImageCanvasView*)view;
- (void)imageCanvasViewRequestNext:(ImageCanvasView*)view;
- (void)imageCanvasViewDidChangeZoom:(ImageCanvasView*)view;
@end

/// Scrollable canvas with zoom (pinch / menu / keyboard) and drag panning via NSScrollView.
@interface ImageCanvasView : NSView

@property(nonatomic, weak, nullable) id<ImageCanvasViewDelegate> delegate;
@property(nonatomic, strong, nullable) NSImage* image;
@property(nonatomic, assign, readonly) CGFloat zoomFactor;

- (void)setImage:(nullable NSImage*)image fitToView:(BOOL)fitToView;
- (void)zoomIn;
- (void)zoomOut;
- (void)zoomActualSize;
- (void)zoomToFit;
- (void)magnifyBy:(CGFloat)delta;  // cumulative scale factor delta for trackpad

@end

NS_ASSUME_NONNULL_END
