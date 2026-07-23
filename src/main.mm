#import "AppDelegate.h"

#include <cstdlib>

// Program entry. Uses NSApplicationMain so AppKit owns the run loop.
// AppDelegate builds the menu and a single MainWindowController.
int main(int argc, const char* argv[]) {
  @autoreleasepool {
    NSApplication* app = [NSApplication sharedApplication];
    // Regular policy so we appear in the Dock and get a menu bar when launched
    // from Terminal / CMake (not as a background accessory app).
    app.activationPolicy = NSApplicationActivationPolicyRegular;

    AppDelegate* delegate = [[AppDelegate alloc] init];
    app.delegate = delegate;

    // Bring forward when launched from Terminal / CMake.
    [app activateIgnoringOtherApps:YES];

    return NSApplicationMain(argc, argv);
  }
}
