#import "AppDelegate.h"

#include <cstdlib>

int main(int argc, const char* argv[]) {
  @autoreleasepool {
    NSApplication* app = [NSApplication sharedApplication];
    app.activationPolicy = NSApplicationActivationPolicyRegular;

    AppDelegate* delegate = [[AppDelegate alloc] init];
    app.delegate = delegate;

    // Bring forward when launched from Terminal / CMake.
    [app activateIgnoringOtherApps:YES];

    return NSApplicationMain(argc, argv);
  }
}
