#import "AppDelegate.h"
#import "SettingsWindowController.h"

@implementation AppDelegate

- (void)setupMenu {
  NSMenu *menubar = [[NSMenu alloc] init];
  NSMenuItem *appMenuItem = [[NSMenuItem alloc] init];
  [menubar addItem:appMenuItem];
  [NSApp setMainMenu:menubar];

  NSMenu *appMenu = [[NSMenu alloc] init];
  NSString *appName = [[NSProcessInfo processInfo] processName];

  // Preferences
  NSMenuItem *prefMenuItem =
      [[NSMenuItem alloc] initWithTitle:@"Preferences..."
                                 action:@selector(showPreferences:)
                          keyEquivalent:@","];
  [appMenu addItem:prefMenuItem];

  [appMenu addItem:[NSMenuItem separatorItem]];

  // Quit
  NSString *quitTitle = [@"Quit " stringByAppendingString:appName];
  NSMenuItem *quitMenuItem =
      [[NSMenuItem alloc] initWithTitle:quitTitle
                                 action:@selector(terminate:)
                          keyEquivalent:@"q"];
  [appMenu addItem:quitMenuItem];
  [appMenuItem setSubmenu:appMenu];

  // Edit Menu (for Focus Search)
  NSMenuItem *editMenuItem = [[NSMenuItem alloc] init];
  [menubar addItem:editMenuItem];
  NSMenu *editMenu = [[NSMenu alloc] initWithTitle:@"Edit"];

  // Standard Edit items (Cut/Copy/Paste) are handled automatically by responder
  // chain if we add them, but for now we just want Focus Search
  NSMenuItem *focusSearchItem =
      [[NSMenuItem alloc] initWithTitle:@"Focus Search"
                                 action:@selector(focusSearch:)
                          keyEquivalent:@"l"];
  [editMenu addItem:focusSearchItem];
  [editMenuItem setSubmenu:editMenu];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  // Create the window
  NSRect frame = NSMakeRect(0, 0, 400, 600);
  NSUInteger styleMask = NSWindowStyleMaskTitled | NSWindowStyleMaskClosable |
                         NSWindowStyleMaskResizable |
                         NSWindowStyleMaskMiniaturizable;
  self.window = [[NSWindow alloc] initWithContentRect:frame
                                            styleMask:styleMask
                                              backing:NSBackingStoreBuffered
                                                defer:NO];
  [self.window setTitle:@"MacOS Utility"];
  [self.window center];
  [self.window makeKeyAndOrderFront:nil];
  [NSApp activateIgnoringOtherApps:YES];

  [self setupMenu];

  // Create a main container view (standard NSView)
  NSView *contentView = [[NSView alloc] initWithFrame:frame];
  self.window.contentView = contentView;

  // 1. Search Field (Input)
  self.inputField = [[NSSearchField alloc] init];
  self.inputField.placeholderString = @"Search...";
  self.inputField.translatesAutoresizingMaskIntoConstraints = NO;
  [contentView addSubview:self.inputField];

  // 2. Scrollable table with 2 cols
  // Give it an initial frame so it has a height to preserve
  NSScrollView *tableScrollView =
      [[NSScrollView alloc] initWithFrame:NSMakeRect(0, 0, 400, 150)];
  tableScrollView.hasVerticalScroller = YES;
  tableScrollView.hasHorizontalScroller = YES;
  tableScrollView.autohidesScrollers = YES;
  tableScrollView.borderType = NSNoBorder; // No border for full width look

  self.tableView = [[NSTableView alloc] init];
  self.tableView.dataSource = self;
  self.tableView.delegate = self;
  self.tableView.usesAlternatingRowBackgroundColors = YES;
  self.tableView.columnAutoresizingStyle =
      NSTableViewUniformColumnAutoresizingStyle;

  // Column 1: Name
  NSTableColumn *nameCol = [[NSTableColumn alloc] initWithIdentifier:@"Name"];
  nameCol.title = @"Name";
  nameCol.width = 200;
  [self.tableView addTableColumn:nameCol];

  // Column 2: Date Modified
  NSTableColumn *dateCol = [[NSTableColumn alloc] initWithIdentifier:@"Date"];
  dateCol.title = @"Date Modified";
  dateCol.width = 150;
  [self.tableView addTableColumn:dateCol];

  tableScrollView.documentView = self.tableView;

  // 3. Text area filling the rest of the space
  NSScrollView *textScrollView =
      [[NSScrollView alloc] initWithFrame:NSMakeRect(0, 0, 400, 300)];
  textScrollView.hasVerticalScroller = YES;
  textScrollView.borderType = NSNoBorder; // No border

  self.textView = [[NSTextView alloc] initWithFrame:NSMakeRect(0, 0, 100, 100)];
  self.textView.minSize = NSMakeSize(0.0, 0.0);
  self.textView.maxSize = NSMakeSize(FLT_MAX, FLT_MAX);
  self.textView.verticallyResizable = YES;
  self.textView.horizontallyResizable = NO;
  self.textView.autoresizingMask = NSViewWidthSizable;
  self.textView.textContainer.containerSize = NSMakeSize(100, FLT_MAX);
  self.textView.textContainer.widthTracksTextView = YES;

  textScrollView.documentView = self.textView;

  // 4. Split View
  self.splitView =
      [[NSSplitView alloc] initWithFrame:NSMakeRect(0, 0, 400, 450)];
  self.splitView.dividerStyle = NSSplitViewDividerStyleThin;
  self.splitView.vertical =
      NO; // Horizontal dividers (items stacked vertically)
  self.splitView.delegate = self; // Set delegate to control sizing
  self.splitView.translatesAutoresizingMaskIntoConstraints = NO;
  [self.splitView addSubview:tableScrollView];
  [self.splitView addSubview:textScrollView];

  // Holding priority: Table View should hold its size (250), Text View should
  // grow (249) Note: With the delegate method implemented, these might be
  // ignored, but good to keep.
  [self.splitView setHoldingPriority:250 forSubviewAtIndex:0];
  [self.splitView setHoldingPriority:249 forSubviewAtIndex:1];

  [contentView addSubview:self.splitView];

  // Layout Constraints
  NSDictionary *views =
      @{@"input" : self.inputField, @"split" : self.splitView};

  // Input field: 10px margin top/left/right
  [contentView
      addConstraints:[NSLayoutConstraint
                         constraintsWithVisualFormat:@"H:|-10-[input]-10-|"
                                             options:0
                                             metrics:nil
                                               views:views]];
  [contentView
      addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:
                                             @"V:|-10-[input]-10-[split]-0-|"
                                                             options:0
                                                             metrics:nil
                                                               views:views]];

  // Split view: 0px margin left/right/bottom
  [contentView
      addConstraints:[NSLayoutConstraint
                         constraintsWithVisualFormat:@"H:|-0-[split]-0-|"
                                             options:0
                                             metrics:nil
                                               views:views]];
  // Force layout to ensure we have a valid frame
  [self.window layoutIfNeeded];

  // Ensure the split position is set correctly
  [self.splitView setPosition:150 ofDividerAtIndex:0];

  // Configure Key View Loop
  [self.inputField setNextKeyView:self.textView];
  [self.textView setNextKeyView:self.inputField];

  // Set initial focus
  [self.window makeFirstResponder:self.inputField];

  // Check/Set Default Preferences
  if (![[NSUserDefaults standardUserDefaults] stringForKey:@"NotesDirectory"]) {
    [[NSUserDefaults standardUserDefaults]
        setObject:[@"~/Documents/notes" stringByExpandingTildeInPath]
           forKey:@"NotesDirectory"];
    [[NSUserDefaults standardUserDefaults] synchronize];
  }
}

- (void)showPreferences:(id)sender {
  [[SettingsWindowController sharedSettingsController] showSettings:sender];
}

- (void)focusSearch:(id)sender {
  [self.window makeFirstResponder:self.inputField];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:
    (NSApplication *)sender {
  return YES;
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
  return 5; // Dummy data
}

- (id)tableView:(NSTableView *)tableView
    objectValueForTableColumn:(NSTableColumn *)tableColumn
                          row:(NSInteger)row {
  if ([tableColumn.identifier isEqualToString:@"Name"]) {
    return [NSString stringWithFormat:@"Item %ld", (long)row];
  } else {
    return [NSDate date];
  }
}

#pragma mark - NSSplitViewDelegate

- (CGFloat)splitView:(NSSplitView *)splitView
    constrainMinCoordinate:(CGFloat)proposedMinimumPosition
               ofSubviewAt:(NSInteger)dividerIndex {
  return 100.0; // Minimum height for the top view (Table)
}

- (CGFloat)splitView:(NSSplitView *)splitView
    constrainMaxCoordinate:(CGFloat)proposedMaximumPosition
               ofSubviewAt:(NSInteger)dividerIndex {
  return splitView.frame.size.height -
         100.0; // Minimum height for the bottom view (Text)
}

- (void)splitView:(NSSplitView *)splitView
    resizeSubviewsWithOldSize:(NSSize)oldSize {
  // Standard resizing behavior: keep top fixed, resize bottom
  CGFloat dividerThickness = [splitView dividerThickness];
  NSRect newFrame = [splitView frame];
  NSRect topFrame = [[splitView.subviews objectAtIndex:0] frame];
  NSRect bottomFrame = [[splitView.subviews objectAtIndex:1] frame];

  // If top frame is collapsed (0 height), force it to default
  if (topFrame.size.height < 1.0) {
    topFrame.size.height = 150.0;
  }

  topFrame.size.width = newFrame.size.width;

  bottomFrame.size.width = newFrame.size.width;
  bottomFrame.size.height =
      newFrame.size.height - topFrame.size.height - dividerThickness;
  bottomFrame.origin.y = topFrame.size.height + dividerThickness;

  [[splitView.subviews objectAtIndex:0] setFrame:topFrame];
  [[splitView.subviews objectAtIndex:1] setFrame:bottomFrame];
}

@end
