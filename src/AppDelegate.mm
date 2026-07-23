#import "AppDelegate.h"
#import "MainWindowController.h"

@interface AppDelegate ()
@property(nonatomic, strong) MainWindowController* mainWindowController;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification*)notification {
  (void)notification;
  self.mainWindowController = [[MainWindowController alloc] init];
  [self.mainWindowController showWindow:nil];
  [self buildMainMenu];
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
  if (!self.mainWindowController) {
    self.mainWindowController = [[MainWindowController alloc] init];
    [self.mainWindowController showWindow:nil];
  }
  [self.mainWindowController openURLs:urls];
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
  [viewMenu addItemWithTitle:@"Enter Full Screen"
                      action:@selector(toggleFullScreen:)
               keyEquivalent:@"f"];

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
