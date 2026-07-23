#import "ImageCanvasView.h"

static const CGFloat kMinZoom = 0.05;
static const CGFloat kMaxZoom = 32.0;
static const CGFloat kZoomStep = 1.25;

typedef NS_ENUM(NSInteger, SIDocScrollMode) {
  /// Scroll so the document/image center is in the middle of the clip.
  SIDocScrollCenter = 0,
  /// Keep the same image point under the viewport center after zoom.
  SIDocScrollPreserveVisibleCenter,
  /// Only clamp the current origin into the new document bounds.
  SIDocScrollClamp,
};

/// Forwards magnify / ⌘+scroll to the owning canvas so zoom stays single-sourced.
@interface SIForwardingScrollView : NSScrollView
@property(nonatomic, weak) ImageCanvasView* canvas;
@end

@implementation SIForwardingScrollView

- (void)magnifyWithEvent:(NSEvent*)event {
  if (self.canvas) {
    [self.canvas magnifyWithEvent:event];
    return;
  }
  [super magnifyWithEvent:event];
}

- (void)scrollWheel:(NSEvent*)event {
  if (self.canvas && (event.modifierFlags & NSEventModifierFlagCommand)) {
    [self.canvas scrollWheel:event];
    return;
  }
  [super scrollWheel:event];
}

- (BOOL)acceptsFirstResponder {
  return NO;
}

- (void)mouseDown:(NSEvent*)event {
  [self.window makeFirstResponder:self.canvas];
  [super mouseDown:event];
}

@end

@interface SIImageHostView : NSImageView
@property(nonatomic, weak) ImageCanvasView* canvas;
@end

@implementation SIImageHostView

- (BOOL)acceptsFirstResponder {
  return NO;
}

- (void)mouseDown:(NSEvent*)event {
  [self.window makeFirstResponder:self.canvas];
  [super mouseDown:event];
}

@end

/// Fills the clip when the image is smaller; clicks restore canvas first responder.
@interface SIDocumentContainer : NSView
@property(nonatomic, weak) ImageCanvasView* canvas;
@end

@implementation SIDocumentContainer

- (BOOL)acceptsFirstResponder {
  return NO;
}

- (void)mouseDown:(NSEvent*)event {
  [self.window makeFirstResponder:self.canvas];
  [super mouseDown:event];
}

@end

@interface ImageCanvasView ()
@property(nonatomic, strong) SIForwardingScrollView* scrollView;
/// Document view: at least as large as the clip view so small images can be centered.
@property(nonatomic, strong) SIDocumentContainer* documentContainer;
@property(nonatomic, strong) SIImageHostView* imageView;
@property(nonatomic, assign) CGFloat zoomFactor;
@property(nonatomic, assign) NSSize imagePixelSize;
@end

@implementation ImageCanvasView

- (instancetype)initWithFrame:(NSRect)frameRect {
  self = [super initWithFrame:frameRect];
  if (self) {
    [self commonInit];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder*)coder {
  self = [super initWithCoder:coder];
  if (self) {
    [self commonInit];
  }
  return self;
}

- (void)commonInit {
  _zoomFactor = 1.0;
  self.wantsLayer = YES;
  self.layer.backgroundColor = NSColor.windowBackgroundColor.CGColor;

  SIDocumentContainer* container = [[SIDocumentContainer alloc] initWithFrame:NSZeroRect];
  container.canvas = self;
  container.wantsLayer = YES;
  container.layer.backgroundColor = [NSColor colorWithWhite:0.12 alpha:1.0].CGColor;
  _documentContainer = container;

  SIImageHostView* imageHost = [[SIImageHostView alloc] initWithFrame:NSZeroRect];
  imageHost.canvas = self;
  imageHost.imageScaling = NSImageScaleAxesIndependently;
  imageHost.imageAlignment = NSImageAlignCenter;
  imageHost.animates = YES;  // GIF
  // Keep keyboard navigation on the canvas after the user clicks the image (#3).
  imageHost.refusesFirstResponder = YES;
  _imageView = imageHost;
  [_documentContainer addSubview:_imageView];

  SIForwardingScrollView* scroll =
      [[SIForwardingScrollView alloc] initWithFrame:self.bounds];
  scroll.canvas = self;
  scroll.hasVerticalScroller = YES;
  scroll.hasHorizontalScroller = YES;
  // Show scrollers when content exceeds the visible area (axis-specific).
  scroll.autohidesScrollers = YES;
  scroll.borderType = NSNoBorder;
  scroll.drawsBackground = YES;
  scroll.backgroundColor = [NSColor colorWithWhite:0.12 alpha:1.0];
  scroll.documentView = _documentContainer;
  scroll.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
  // Single zoom system: frame-based only. Do not use scroll-view magnification (#4).
  scroll.allowsMagnification = NO;

  _scrollView = scroll;
  [self addSubview:_scrollView];
}

- (void)layout {
  [super layout];
  self.scrollView.frame = self.bounds;
  // Keep image centered (or scroll extents correct) when the window resizes.
  [self layoutDocumentWithScrollMode:SIDocScrollClamp];
}

- (BOOL)acceptsFirstResponder {
  return YES;
}

- (void)mouseDown:(NSEvent*)event {
  (void)event;
  // Clicks on empty chrome (or if events bubble here) reclaim first responder.
  [self.window makeFirstResponder:self];
}

- (void)setImage:(NSImage*)image {
  [self setImage:image fitToView:YES];
}

- (void)setImage:(NSImage*)image fitToView:(BOOL)fitToView {
  _image = image;
  self.imageView.image = image;

  if (!image) {
    self.imagePixelSize = NSZeroSize;
    self.imageView.frame = NSZeroRect;
    self.documentContainer.frame = NSZeroRect;
    self.zoomFactor = 1.0;
    [self.scrollView.contentView setBoundsOrigin:NSZeroPoint];
    [self.scrollView reflectScrolledClipView:self.scrollView.contentView];
    return;
  }

  self.imagePixelSize = image.size;

  if (fitToView) {
    [self zoomToFit];
  } else {
    [self applyZoom:1.0 scrollMode:SIDocScrollCenter];
  }
}

/// Lays out document so the image is centered when smaller than the viewport,
/// and the document grows with the image so scrollers appear on overflow axes.
- (void)layoutDocumentWithScrollMode:(SIDocScrollMode)mode {
  if (self.imagePixelSize.width <= 0 || self.imagePixelSize.height <= 0) {
    return;
  }

  // Fraction of the image under the viewport center before we change frames.
  CGFloat focusRelX = 0.5;
  CGFloat focusRelY = 0.5;
  if (mode == SIDocScrollPreserveVisibleCenter) {
    const NSRect oldImage = self.imageView.frame;
    if (oldImage.size.width > 0.5 && oldImage.size.height > 0.5) {
      const NSRect visible = self.scrollView.documentVisibleRect;
      focusRelX = (NSMidX(visible) - oldImage.origin.x) / oldImage.size.width;
      focusRelY = (NSMidY(visible) - oldImage.origin.y) / oldImage.size.height;
      focusRelX = fmax(0.0, fmin(1.0, focusRelX));
      focusRelY = fmax(0.0, fmin(1.0, focusRelY));
    }
  }

  const CGFloat zoom = self.zoomFactor;
  const NSSize imageSize = NSMakeSize(self.imagePixelSize.width * zoom,
                                      self.imagePixelSize.height * zoom);

  // Use the clip view's visible size (content area inside scrollers).
  NSSize clipSize = self.scrollView.contentView.bounds.size;
  if (clipSize.width < 1 || clipSize.height < 1) {
    clipSize = self.scrollView.bounds.size;
  }

  const NSSize docSize =
      NSMakeSize(fmax(imageSize.width, clipSize.width),
                 fmax(imageSize.height, clipSize.height));

  self.documentContainer.frame = NSMakeRect(0, 0, docSize.width, docSize.height);

  // Integral origins avoid half-pixel soft edges on non-Retina.
  const CGFloat imageX = floor((docSize.width - imageSize.width) * 0.5);
  const CGFloat imageY = floor((docSize.height - imageSize.height) * 0.5);
  self.imageView.frame =
      NSMakeRect(imageX, imageY, imageSize.width, imageSize.height);

  const CGFloat maxX = fmax(0.0, docSize.width - clipSize.width);
  const CGFloat maxY = fmax(0.0, docSize.height - clipSize.height);
  NSPoint origin = NSZeroPoint;

  switch (mode) {
    case SIDocScrollCenter:
      origin.x = floor(maxX * 0.5);
      origin.y = floor(maxY * 0.5);
      break;
    case SIDocScrollPreserveVisibleCenter: {
      const CGFloat focusX = imageX + focusRelX * imageSize.width;
      const CGFloat focusY = imageY + focusRelY * imageSize.height;
      origin.x = focusX - clipSize.width * 0.5;
      origin.y = focusY - clipSize.height * 0.5;
      origin.x = fmin(fmax(0.0, origin.x), maxX);
      origin.y = fmin(fmax(0.0, origin.y), maxY);
      break;
    }
    case SIDocScrollClamp: {
      origin = self.scrollView.contentView.bounds.origin;
      origin.x = fmin(fmax(0.0, origin.x), maxX);
      origin.y = fmin(fmax(0.0, origin.y), maxY);
      break;
    }
  }

  [self.scrollView.contentView setBoundsOrigin:origin];
  [self.scrollView reflectScrolledClipView:self.scrollView.contentView];
}

- (void)applyZoom:(CGFloat)zoom {
  [self applyZoom:zoom scrollMode:SIDocScrollPreserveVisibleCenter];
}

- (void)applyZoom:(CGFloat)zoom scrollMode:(SIDocScrollMode)mode {
  zoom = fmax(kMinZoom, fmin(kMaxZoom, zoom));
  self.zoomFactor = zoom;

  if (self.imagePixelSize.width <= 0 || self.imagePixelSize.height <= 0) {
    return;
  }

  [self layoutDocumentWithScrollMode:mode];

  if ([self.delegate respondsToSelector:@selector(imageCanvasViewDidChangeZoom:)]) {
    [self.delegate imageCanvasViewDidChangeZoom:self];
  }
}

- (void)keyDown:(NSEvent*)event {
  NSString* chars = event.charactersIgnoringModifiers;
  if (chars.length == 0) {
    [super keyDown:event];
    return;
  }
  const unichar c = [chars characterAtIndex:0];
  switch (c) {
    case NSLeftArrowFunctionKey:
    case 'p':
    case 'P':
      if ([self.delegate respondsToSelector:@selector(imageCanvasViewRequestPrevious:)]) {
        [self.delegate imageCanvasViewRequestPrevious:self];
      }
      break;
    case NSRightArrowFunctionKey:
    case 'n':
    case 'N':
    case ' ':
      if ([self.delegate respondsToSelector:@selector(imageCanvasViewRequestNext:)]) {
        [self.delegate imageCanvasViewRequestNext:self];
      }
      break;
    case '+':
    case '=':
      [self zoomIn];
      break;
    case '-':
    case '_':
      [self zoomOut];
      break;
    case '0':
      [self zoomActualSize];
      break;
    case '9':
      [self zoomToFit];
      break;
    default:
      [super keyDown:event];
      break;
  }
}

- (void)zoomIn {
  [self applyZoom:self.zoomFactor * kZoomStep
       scrollMode:SIDocScrollPreserveVisibleCenter];
}

- (void)zoomOut {
  [self applyZoom:self.zoomFactor / kZoomStep
       scrollMode:SIDocScrollPreserveVisibleCenter];
}

- (void)zoomActualSize {
  [self applyZoom:1.0 scrollMode:SIDocScrollCenter];
}

- (void)zoomToFit {
  if (self.imagePixelSize.width <= 0 || self.imagePixelSize.height <= 0) {
    return;
  }
  // Ensure scroll view has a real size before measuring the clip.
  [self layoutSubtreeIfNeeded];
  const NSSize visible = self.scrollView.contentView.bounds.size;
  if (visible.width <= 1 || visible.height <= 1) {
    [self applyZoom:1.0 scrollMode:SIDocScrollCenter];
    return;
  }

  const CGFloat sx = visible.width / self.imagePixelSize.width;
  const CGFloat sy = visible.height / self.imagePixelSize.height;
  // Fit entirely inside the window (no scrollbars at fit zoom).
  [self applyZoom:fmin(sx, sy) scrollMode:SIDocScrollCenter];
}

- (void)magnifyBy:(CGFloat)delta {
  [self applyZoom:self.zoomFactor * delta
       scrollMode:SIDocScrollPreserveVisibleCenter];
}

- (void)magnifyWithEvent:(NSEvent*)event {
  const CGFloat factor = event.magnification + 1.0;
  [self applyZoom:self.zoomFactor * factor
       scrollMode:SIDocScrollPreserveVisibleCenter];
}

- (void)scrollWheel:(NSEvent*)event {
  // Command+scroll is zoom-only. Always consume it — never bounce back into
  // SIForwardingScrollView (that re-forwards Command wheels and can recurse).
  if (event.modifierFlags & NSEventModifierFlagCommand) {
    const CGFloat delta = event.scrollingDeltaY;
    if (fabs(delta) > 0.1) {
      const CGFloat factor = (delta > 0) ? 1.05 : (1.0 / 1.05);
      [self applyZoom:self.zoomFactor * factor
           scrollMode:SIDocScrollPreserveVisibleCenter];
    }
    return;
  }
  // Do not call [scrollView scrollWheel:] here: if NSScrollView does not
  // fully consume the event, nextResponder is this canvas and re-entry loops.
  // Normal pan is handled when the event hits the scroll view first.
  [super scrollWheel:event];
}

@end
