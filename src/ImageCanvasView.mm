#import "ImageCanvasView.h"

static const CGFloat kMinZoom = 0.05;
static const CGFloat kMaxZoom = 32.0;
static const CGFloat kZoomStep = 1.25;

@interface ImageCanvasView ()
@property(nonatomic, strong) NSScrollView* scrollView;
@property(nonatomic, strong) NSImageView* imageView;
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

  _imageView = [[NSImageView alloc] initWithFrame:NSZeroRect];
  _imageView.imageScaling = NSImageScaleAxesIndependently;
  _imageView.imageAlignment = NSImageAlignCenter;
  _imageView.animates = YES;  // GIF

  _scrollView = [[NSScrollView alloc] initWithFrame:self.bounds];
  _scrollView.hasVerticalScroller = YES;
  _scrollView.hasHorizontalScroller = YES;
  _scrollView.autohidesScrollers = YES;
  _scrollView.borderType = NSNoBorder;
  _scrollView.drawsBackground = YES;
  _scrollView.backgroundColor = [NSColor colorWithCalibratedWhite:0.12 alpha:1.0];
  _scrollView.documentView = _imageView;
  _scrollView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
  _scrollView.allowsMagnification = YES;
  _scrollView.minMagnification = kMinZoom;
  _scrollView.maxMagnification = kMaxZoom;

  [self addSubview:_scrollView];
}

- (void)layout {
  [super layout];
  self.scrollView.frame = self.bounds;
}

- (BOOL)acceptsFirstResponder {
  return YES;
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
  // Reset magnification so scroll view magnification doesn't compound with frame scaling.
  self.scrollView.magnification = 1.0;
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
  // delta is typically magnification - 1 from magnify gesture, or a factor.
  [self applyZoom:self.zoomFactor * delta];
}

- (void)magnifyWithEvent:(NSEvent*)event {
  const CGFloat factor = event.magnification + 1.0;
  [self applyZoom:self.zoomFactor * factor];
}

- (void)scrollWheel:(NSEvent*)event {
  if (event.modifierFlags & NSEventModifierFlagCommand) {
    const CGFloat delta = event.scrollingDeltaY;
    if (fabs(delta) > 0.1) {
      const CGFloat factor = (delta > 0) ? 1.05 : (1.0 / 1.05);
      [self applyZoom:self.zoomFactor * factor];
      return;
    }
  }
  [super scrollWheel:event];
}

@end
