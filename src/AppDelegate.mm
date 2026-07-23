#import "AppDelegate.h"
#import "MainWindowController.h"

@interface AppDelegate ()
@property(nonatomic, strong) MainWindowController* mainWindowController;
@property(nonatomic, strong) NSMutableArray<NSURL*>* pendingOpenURLs;
@property(nonatomic, assign) BOOL didFinishLaunching;
@end

@implementation AppDelegate

- (MainWindowController*)ensureMainWindowController {
  if (!self.mainWindowController) {
    self.mainWindowController = [[MainWindowController alloc] init];
  }
  return self.mainWindowController;
}

- (void)applicationDidFinishLaunching:(NSNotification*)notification {
  (void)notification;
  self.didFinishLaunching = YES;
  [self ensureMainWindowController];
  [self.mainWindowController showWindow:nil];
  [self buildMainMenu];

  if (self.pendingOpenURLs.count > 0) {
    NSArray<NSURL*>* urls = [self.pendingOpenURLs copy];
    [self.pendingOpenURLs removeAllObjects];
    [self.mainWindowController openURLs:urls];
  }
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication*)sender {
  (void)sender;
  return YES;
}

- (BOOL)applicationSupportsSecureRestorableState:(NSApplication*)app {
  (void)app;
  return YES;
}

/// Open files dropped on the Dock icon / opened from Finder.
- (void)application:(NSApplication*)application openURLs:(NSArray<NSURL*>*)urls {
  (void)application;
  if (urls.count == 0) {
    return;
  }

  // Before launch finishes, queue URLs so we do not create a controller that
  // didFinishLaunching would later discard. Append if the system delivers
  // multiple openURL batches before launch completes.
  if (!self.didFinishLaunching) {
    if (!self.pendingOpenURLs) {
      self.pendingOpenURLs = [NSMutableArray array];
    }
    [self.pendingOpenURLs addObjectsFromArray:urls];
    return;
  }

  MainWindowController* controller = [self ensureMainWindowController];
  [controller showWindow:nil];
  [controller openURLs:urls];
}

- (void)buildMainMenu {
  NSMenu* menubar = [[NSMenu alloc] initWithTitle:@""];
  NSApp.mainMenu = menubar;

  // App menu
  NSMenuItem* appItem = [[NSMenuItem alloc] init];
  [menubar addItem:appItem];
  NSMenu* appMenu = [[NSMenu alloc] initWithTitle:@"ShowImage"];
  appItem.submenu = appMenu;

  [appMenu addItemWithTitle:@"About ShowImage"
                     action:@selector(orderFrontStandardAboutPanel:)
              keyEquivalent:@""];
  [appMenu addItem:[NSMenuItem separatorItem]];
  [appMenu addItemWithTitle:@"Quit ShowImage"
                     action:@selector(terminate:)
              keyEquivalent:@"q"];

  // File
  NSMenuItem* fileItem = [[NSMenuItem alloc] init];
  [menubar addItem:fileItem];
  NSMenu* fileMenu = [[NSMenu alloc] initWithTitle:@"File"];
  fileItem.submenu = fileMenu;

  [fileMenu addItemWithTitle:@"Open…"
                      action:@selector(openDocument:)
               keyEquivalent:@"o"];
  [fileMenu addItemWithTitle:@"Open Folder…"
                      action:@selector(openFolder:)
               keyEquivalent:@"O"];
  [fileMenu addItem:[NSMenuItem separatorItem]];
  [fileMenu addItemWithTitle:@"Close Window"
                      action:@selector(performClose:)
               keyEquivalent:@"w"];

  // View
  NSMenuItem* viewItem = [[NSMenuItem alloc] init];
  [menubar addItem:viewItem];
  NSMenu* viewMenu = [[NSMenu alloc] initWithTitle:@"View"];
  viewItem.submenu = viewMenu;

  [viewMenu addItemWithTitle:@"Actual Size"
                      action:@selector(zoomActualSize:)
               keyEquivalent:@"0"];
  [viewMenu addItemWithTitle:@"Zoom to Fit"
                      action:@selector(zoomToFit:)
               keyEquivalent:@"9"];
  [viewMenu addItemWithTitle:@"Zoom In"
                      action:@selector(zoomIn:)
               keyEquivalent:@"+"];
  [viewMenu addItemWithTitle:@"Zoom Out"
                      action:@selector(zoomOut:)
               keyEquivalent:@"-"];
  [viewMenu addItem:[NSMenuItem separatorItem]];

  // macOS standard: Control-Command-F for Enter Full Screen (#5).
  NSMenuItem* fullScreenItem =
      [viewMenu addItemWithTitle:@"Enter Full Screen"
                          action:@selector(toggleFullScreen:)
                   keyEquivalent:@"f"];
  fullScreenItem.keyEquivalentModifierMask =
      NSEventModifierFlagControl | NSEventModifierFlagCommand;

  // Go
  NSMenuItem* goItem = [[NSMenuItem alloc] init];
  [menubar addItem:goItem];
  NSMenu* goMenu = [[NSMenu alloc] initWithTitle:@"Go"];
  goItem.submenu = goMenu;

  // Arrow keys are handled in ImageCanvasView; menu uses [ / ] for discoverability.
  [goMenu addItemWithTitle:@"Previous Image"
                    action:@selector(previousImage:)
             keyEquivalent:@"["];
  [goMenu addItemWithTitle:@"Next Image"
                    action:@selector(nextImage:)
             keyEquivalent:@"]"];

  // Window
  NSMenuItem* windowItem = [[NSMenuItem alloc] init];
  [menubar addItem:windowItem];
  NSMenu* windowMenu = [[NSMenu alloc] initWithTitle:@"Window"];
  windowItem.submenu = windowMenu;
  NSApp.windowsMenu = windowMenu;
  [windowMenu addItemWithTitle:@"Minimize"
                        action:@selector(performMiniaturize:)
                 keyEquivalent:@"m"];
  [windowMenu addItemWithTitle:@"Zoom"
                        action:@selector(performZoom:)
                 keyEquivalent:@""];
}

@end
