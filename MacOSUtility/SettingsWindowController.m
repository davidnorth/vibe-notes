#import "SettingsWindowController.h"

@implementation SettingsWindowController

+ (instancetype)sharedSettingsController {
  static SettingsWindowController *sharedController = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedController = [[SettingsWindowController alloc] init];
  });
  return sharedController;
}

- (instancetype)init {
  // Create window programmatically
  NSRect frame = NSMakeRect(0, 0, 400, 150);
  NSWindow *window = [[NSWindow alloc]
      initWithContentRect:frame
                styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable
                  backing:NSBackingStoreBuffered
                    defer:NO];
  [window setTitle:@"Preferences"];

  self = [super initWithWindow:window];
  if (self) {
    [self setupUI];
  }
  return self;
}

- (void)setupUI {
  NSView *contentView = self.window.contentView;

  // Label
  NSTextField *label =
      [[NSTextField alloc] initWithFrame:NSMakeRect(20, 100, 180, 20)];
  [label setStringValue:@"Read notes from folder:"];
  [label setBezeled:NO];
  [label setDrawsBackground:NO];
  [label setEditable:NO];
  [label setSelectable:NO];
  [contentView addSubview:label];

  // PopUp Button
  self.pathPopUp =
      [[NSPopUpButton alloc] initWithFrame:NSMakeRect(200, 98, 180, 25)
                                 pullsDown:NO];
  [self.pathPopUp setTarget:self];
  [self.pathPopUp setAction:@selector(pathSelectionChanged:)];
  [contentView addSubview:self.pathPopUp];

  [self updatePopUpMenu];
}

- (void)updatePopUpMenu {
  [self.pathPopUp removeAllItems];

  NSString *currentPath =
      [[NSUserDefaults standardUserDefaults] stringForKey:@"NotesDirectory"];
  if (!currentPath) {
    currentPath = [@"~/Documents/notes" stringByExpandingTildeInPath];
  }

  [self.pathPopUp addItemWithTitle:[currentPath lastPathComponent]];
  [[self.pathPopUp lastItem] setRepresentedObject:currentPath];
  [[self.pathPopUp lastItem] setToolTip:currentPath];

  [self.pathPopUp.menu addItem:[NSMenuItem separatorItem]];

  [self.pathPopUp addItemWithTitle:@"Other..."];
}

- (void)pathSelectionChanged:(id)sender {
  NSMenuItem *selectedItem = [self.pathPopUp selectedItem];
  if ([[selectedItem title] isEqualToString:@"Other..."]) {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setCanChooseFiles:NO];
    [panel setCanChooseDirectories:YES];
    [panel setAllowsMultipleSelection:NO];

    [panel beginSheetModalForWindow:self.window
                  completionHandler:^(NSModalResponse result) {
                    if (result == NSModalResponseOK) {
                      NSURL *url = [panel URL];
                      NSString *path = [url path];
                      [[NSUserDefaults standardUserDefaults]
                          setObject:path
                             forKey:@"NotesDirectory"];
                      [[NSUserDefaults standardUserDefaults] synchronize];
                    }
                    // Always refresh menu to show current selection (or revert
                    // if cancelled)
                    [self updatePopUpMenu];
                    [self.pathPopUp selectItemAtIndex:0];
                  }];
  }
}

- (void)showSettings:(id)sender {
  [self updatePopUpMenu];
  [self.window center];
  [self.window makeKeyAndOrderFront:sender];
}

@end
