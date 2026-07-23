#import "MainWindowController.h"

#import "ImageCanvasView.h"
#import "ImageLoader.h"
#import "SandboxAccess.h"

#include "showimage/image_list.hpp"
#include "showimage/supported_formats.hpp"

#include <string>

@interface MainWindowController ()
@property(nonatomic, strong) ImageCanvasView* canvas;
@property(nonatomic, strong) NSTextField* statusLabel;
@property(nonatomic, strong) SandboxAccess* sandboxAccess;
@property(nonatomic, assign) showimage::ImageList* imageList;
@end

@implementation MainWindowController

- (instancetype)init {
  NSWindow* window =
      [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 960, 720)
                                  styleMask:NSWindowStyleMaskTitled |
                                            NSWindowStyleMaskClosable |
                                            NSWindowStyleMaskMiniaturizable |
                                            NSWindowStyleMaskResizable |
                                            NSWindowStyleMaskFullSizeContentView
                                    backing:NSBackingStoreBuffered
                                      defer:NO];
  window.title = @"ShowImage";
  window.titlebarAppearsTransparent = YES;
  window.collectionBehavior =
      NSWindowCollectionBehaviorFullScreenPrimary;
  window.minSize = NSMakeSize(320, 240);
  window.releasedWhenClosed = NO;

  self = [super initWithWindow:window];
  if (self) {
    _sandboxAccess = [[SandboxAccess alloc] init];
    _imageList = new showimage::ImageList();
    window.delegate = self;
    [self buildContentView];
    [window center];
    [self updateStatus];
  }
  return self;
}

- (void)dealloc {
  delete _imageList;
  _imageList = nullptr;
}

- (void)buildContentView {
  NSView* content = self.window.contentView;

  self.canvas = [[ImageCanvasView alloc] initWithFrame:content.bounds];
  self.canvas.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
  self.canvas.delegate = self;

  self.statusLabel = [[NSTextField alloc] initWithFrame:NSZeroRect];
  self.statusLabel.editable = NO;
  self.statusLabel.bezeled = NO;
  self.statusLabel.drawsBackground = YES;
  self.statusLabel.backgroundColor =
      [[NSColor blackColor] colorWithAlphaComponent:0.55];
  self.statusLabel.textColor = NSColor.whiteColor;
  self.statusLabel.font = [NSFont monospacedDigitSystemFontOfSize:12
                                                           weight:NSFontWeightRegular];
  self.statusLabel.alignment = NSTextAlignmentCenter;
  self.statusLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
  self.statusLabel.autoresizingMask =
      NSViewWidthSizable | NSViewMinYMargin;

  [content addSubview:self.canvas];
  [content addSubview:self.statusLabel];
  [self layoutChrome];
}

- (void)layoutChrome {
  NSView* content = self.window.contentView;
  const CGFloat statusH = 24.0;
  NSRect bounds = content.bounds;
  self.statusLabel.frame =
      NSMakeRect(0, 0, bounds.size.width, statusH);
  self.canvas.frame =
      NSMakeRect(0, statusH, bounds.size.width, bounds.size.height - statusH);
}

- (void)windowDidResize:(NSNotification*)notification {
  (void)notification;
  [self layoutChrome];
}

#pragma mark - Open

- (IBAction)openDocument:(id)sender {
  (void)sender;
  NSOpenPanel* panel = [NSOpenPanel openPanel];
  panel.canChooseFiles = YES;
  panel.canChooseDirectories = NO;
  panel.allowsMultipleSelection = NO;
  panel.canCreateDirectories = NO;
  panel.message = @"Choose an image to view.";
  panel.prompt = @"Open";

  if (@available(macOS 11.0, *)) {
    // Prefer UTTypes when available; keep permissive for ImageIO formats.
    panel.allowedContentTypes = @[];
    panel.allowsOtherFileTypes = YES;
  }

  __weak MainWindowController* weakSelf = self;
  [panel beginSheetModalForWindow:self.window
                completionHandler:^(NSModalResponse result) {
                  if (result != NSModalResponseOK) {
                    return;
                  }
                  [weakSelf openURLs:panel.URLs];
                }];
}

- (IBAction)openFolder:(id)sender {
  (void)sender;
  NSOpenPanel* panel = [NSOpenPanel openPanel];
  panel.canChooseFiles = NO;
  panel.canChooseDirectories = YES;
  panel.allowsMultipleSelection = NO;
  panel.message =
      @"Choose a folder to browse. App Sandbox requires this for Previous/Next.";
  panel.prompt = @"Open Folder";

  __weak MainWindowController* weakSelf = self;
  [panel beginSheetModalForWindow:self.window
                completionHandler:^(NSModalResponse result) {
                  if (result != NSModalResponseOK || panel.URLs.count == 0) {
                    return;
                  }
                  [weakSelf openFolderURL:panel.URLs.firstObject];
                }];
}

- (void)openURLs:(NSArray<NSURL*>*)urls {
  if (urls.count == 0) {
    return;
  }
  NSURL* url = urls.firstObject;

  // Directory drops / Open With folder URLs (#2).
  BOOL isDirectory = NO;
  if (url.hasDirectoryPath) {
    isDirectory = YES;
  } else {
    NSNumber* dirValue = nil;
    if ([url getResourceValue:&dirValue forKey:NSURLIsDirectoryKey error:nil] &&
        dirValue.boolValue) {
      isDirectory = YES;
    }
  }
  if (isDirectory) {
    [self openFolderURL:url];
    [self.window makeKeyAndOrderFront:nil];
    return;
  }

  [self.sandboxAccess stopAll];
  [self.sandboxAccess startAccessingURL:url];

  const std::string path = url.path.UTF8String;
  self.imageList->SetSingleFile(path);

  // Best-effort: if parent directory is readable (non-sandbox or granted), scan it.
  NSURL* parent = url.URLByDeletingLastPathComponent;
  if ([self canListDirectory:parent]) {
    [self.sandboxAccess startAccessingURL:parent];
    self.imageList->ScanDirectorySelecting(parent.path.UTF8String, path);
  }

  [self displayCurrentImage];
  [self.window makeKeyAndOrderFront:nil];
}

- (void)openFolderURL:(NSURL*)folderURL {
  [self.sandboxAccess stopAll];
  [self.sandboxAccess startAccessingURL:folderURL];

  const std::size_t count =
      self.imageList->ScanDirectory(folderURL.path.UTF8String);
  if (count == 0) {
    self.canvas.image = nil;
    [self updateStatusWithMessage:@"No supported images in this folder."];
    return;
  }
  [self displayCurrentImage];
}

- (BOOL)canListDirectory:(NSURL*)directoryURL {
  if (!directoryURL) {
    return NO;
  }
  NSError* error = nil;
  NSArray* contents =
      [[NSFileManager defaultManager] contentsOfDirectoryAtURL:directoryURL
                                    includingPropertiesForKeys:nil
                                                       options:0
                                                         error:&error];
  return contents != nil && error == nil;
}

#pragma mark - Navigation

- (IBAction)previousImage:(id)sender {
  (void)sender;
  if (self.imageList->Navigate(showimage::NavigateDirection::Previous)) {
    [self displayCurrentImage];
  }
}

- (IBAction)nextImage:(id)sender {
  (void)sender;
  if (self.imageList->Navigate(showimage::NavigateDirection::Next)) {
    [self displayCurrentImage];
  }
}

#pragma mark - Zoom

- (IBAction)zoomIn:(id)sender {
  (void)sender;
  [self.canvas zoomIn];
  [self updateStatus];
}

- (IBAction)zoomOut:(id)sender {
  (void)sender;
  [self.canvas zoomOut];
  [self updateStatus];
}

- (IBAction)zoomActualSize:(id)sender {
  (void)sender;
  [self.canvas zoomActualSize];
  [self updateStatus];
}

- (IBAction)zoomToFit:(id)sender {
  (void)sender;
  [self.canvas zoomToFit];
  [self updateStatus];
}

#pragma mark - Display

- (void)displayCurrentImage {
  auto current = self.imageList->Current();
  if (!current) {
    self.canvas.image = nil;
    self.window.title = @"ShowImage";
    [self updateStatusWithMessage:@"No image open. File → Open… or Open Folder…"];
    return;
  }

  NSURL* url = [NSURL fileURLWithPath:@(current->path.c_str())];
  NSError* error = nil;
  NSImage* image = [ImageLoader imageAtURL:url error:&error];
  if (!image) {
    self.canvas.image = nil;
    self.window.title = @"ShowImage";
    NSString* msg =
        error.localizedDescription ?: @"Failed to load image.";
    [self updateStatusWithMessage:msg];
    return;
  }

  [self.canvas setImage:image fitToView:YES];
  self.window.representedURL = url;
  self.window.title = @(current->fileName.c_str());
  [self updateStatus];
  [self.window makeFirstResponder:self.canvas];
}

- (void)updateStatus {
  auto current = self.imageList->Current();
  if (!current) {
    [self updateStatusWithMessage:
              [NSString stringWithFormat:@"Ready — %@",
                                         @(showimage::SupportedFormatsDescription().c_str())]];
    return;
  }

  const NSSize px = self.canvas.image.size;
  const NSUInteger idx = static_cast<NSUInteger>(self.imageList->Index() + 1);
  const NSUInteger total = static_cast<NSUInteger>(self.imageList->Size());
  const NSInteger zoomPct =
      static_cast<NSInteger>(llround(self.canvas.zoomFactor * 100.0));

  NSString* msg = [NSString
      stringWithFormat:@"%@  •  %.0f×%.0f  •  %ld%%  •  %lu / %lu",
                       @(current->fileName.c_str()), px.width, px.height,
                       (long)zoomPct, (unsigned long)idx, (unsigned long)total];
  if (total <= 1) {
    msg = [msg stringByAppendingString:@"  •  Open Folder… for Previous/Next"];
  }
  [self updateStatusWithMessage:msg];
}

- (void)updateStatusWithMessage:(NSString*)message {
  self.statusLabel.stringValue = message ?: @"";
}

#pragma mark - ImageCanvasViewDelegate

- (void)imageCanvasViewRequestPrevious:(ImageCanvasView*)view {
  (void)view;
  [self previousImage:nil];
}

- (void)imageCanvasViewRequestNext:(ImageCanvasView*)view {
  (void)view;
  [self nextImage:nil];
}

- (void)imageCanvasViewDidChangeZoom:(ImageCanvasView*)view {
  (void)view;
  [self updateStatus];
}

@end
