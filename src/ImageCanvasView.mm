#import "ImageCanvasView.h"

static const CGFloat kMinZoom = 0.05;
static const CGFloat kMaxZoom = 32.0;
static const CGFloat kZoomStep = 1.25;

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

@interface ImageCanvasView ()
@property(nonatomic, strong) SIForwardingScrollView* scrollView;
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

  SIImageHostView* imageHost = [[SIImageHostView alloc] initWithFrame:NSZeroRect];
  imageHost.canvas = self;
  imageHost.imageScaling = NSImageScaleAxesIndependently;
  imageHost.imageAlignment = NSImageAlignCenter;
  imageHost.animates = YES;  // GIF
  // Keep keyboard navigation on the canvas after the user clicks the image (#3).
  imageHost.refusesFirstResponder = YES;
  _imageView = imageHost;

  SIForwardingScrollView* scroll =
      [[SIForwardingScrollView alloc] initWithFrame:self.bounds];
  scroll.canvas = self;
  scroll.hasVerticalScroller = YES;
  scroll.hasHorizontalScroller = YES;
  scroll.autohidesScrollers = YES;
  scroll.borderType = NSNoBorder;
  scroll.drawsBackground = YES;
  scroll.backgroundColor = [NSColor colorWithWhite:0.12 alpha:1.0];
  scroll.documentView = _imageView;
  scroll.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
  // Single zoom system: frame-based only. Do not use scroll-view magnification (#4).
  scroll.allowsMagnification = NO;

  _scrollView = scroll;
  [self addSubview:_scrollView];
}

- (void)layout {
  [super layout];
  self.scrollView.frame = self.bounds;
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
    self.zoomFactor = 1.0;
    return;
  }

  self.imagePixelSize = image.size;
  self.imageView.frame = NSMakeRect(0, 0, image.size.width, image.size.height);
  [self.scrollView.contentView setBoundsOrigin:NSZeroPoint];

  if (fitToView) {
    [self zoomToFit];
  } else {
    [self applyZoom:1.0];
  }
}

- (void)applyZoom:(CGFloat)zoom {
  zoom = fmax(kMinZoom, fmin(kMaxZoom, zoom));
  self.zoomFactor = zoom;

  if (self.imagePixelSize.width <= 0 || self.imagePixelSize.height <= 0) {
    return;
  }

  const NSSize size = NSMakeSize(self.imagePixelSize.width * zoom,
                                 self.imagePixelSize.height * zoom);
  self.imageView.frame = NSMakeRect(0, 0, size.width, size.height);
  [self.scrollView reflectScrolledClipView:self.scrollView.contentView];

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
  [self applyZoom:self.zoomFactor * kZoomStep];
}

- (void)zoomOut {
  [self applyZoom:self.zoomFactor / kZoomStep];
}

- (void)zoomActualSize {
  [self applyZoom:1.0];
}

- (void)zoomToFit {
  if (self.imagePixelSize.width <= 0 || self.imagePixelSize.height <= 0) {
    return;
  }
  const NSSize visible = self.scrollView.contentView.bounds.size;
  if (visible.width <= 1 || visible.height <= 1) {
    [self applyZoom:1.0];
    return;
  }

  const CGFloat sx = visible.width / self.imagePixelSize.width;
  const CGFloat sy = visible.height / self.imagePixelSize.height;
  [self applyZoom:fmin(sx, sy)];
}

- (void)magnifyBy:(CGFloat)delta {
  [self applyZoom:self.zoomFactor * delta];
}

- (void)magnifyWithEvent:(NSEvent*)event {
  const CGFloat factor = event.magnification + 1.0;
  [self applyZoom:self.zoomFactor * factor];
}

- (void)scrollWheel:(NSEvent*)event {
  // Command+scroll is zoom-only. Always consume it — never bounce back into
  // SIForwardingScrollView (that re-forwards Command wheels and can recurse).
  if (event.modifierFlags & NSEventModifierFlagCommand) {
    const CGFloat delta = event.scrollingDeltaY;
    if (fabs(delta) > 0.1) {
      const CGFloat factor = (delta > 0) ? 1.05 : (1.0 / 1.05);
      [self applyZoom:self.zoomFactor * factor];
    }
    return;
  }
  [self.scrollView scrollWheel:event];
}

@end
