#import "AppDelegate.h"
#import "Note.h"
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

  // Edit Menu
  NSMenuItem *editMenuItem = [[NSMenuItem alloc] init];
  [menubar addItem:editMenuItem];
  NSMenu *editMenu = [[NSMenu alloc] initWithTitle:@"Edit"];

  [editMenu addItemWithTitle:@"Undo"
                      action:@selector(undo:)
               keyEquivalent:@"z"];
  [editMenu addItemWithTitle:@"Redo"
                      action:@selector(redo:)
               keyEquivalent:@"Z"];
  [editMenu addItem:[NSMenuItem separatorItem]];
  [editMenu addItemWithTitle:@"Cut" action:@selector(cut:) keyEquivalent:@"x"];
  [editMenu addItemWithTitle:@"Copy"
                      action:@selector(copy:)
               keyEquivalent:@"c"];
  [editMenu addItemWithTitle:@"Paste"
                      action:@selector(paste:)
               keyEquivalent:@"v"];
  [editMenu addItemWithTitle:@"Select All"
                      action:@selector(selectAll:)
               keyEquivalent:@"a"];
  [editMenu addItem:[NSMenuItem separatorItem]];

  NSMenuItem *deleteItem =
      [[NSMenuItem alloc] initWithTitle:@"Delete Note"
                                 action:@selector(deleteNote:)
                          keyEquivalent:@"\b"];
  [deleteItem setKeyEquivalentModifierMask:NSEventModifierFlagCommand];
  [editMenu addItem:deleteItem];

  [editMenu addItem:[NSMenuItem separatorItem]];

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
  [self.window setTitle:@"VibeNote"];
  [self.window center];
  [self.window makeKeyAndOrderFront:nil];
  [NSApp activateIgnoringOtherApps:YES];

  [self setupMenu];
  [self setupUserInterface];

  // Observe text changes for auto-save
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(textDidChange:)
                                               name:NSTextDidChangeNotification
                                             object:self.textView];

  // Check/Set Default Preferences
  if (![[NSUserDefaults standardUserDefaults] stringForKey:@"NotesDirectory"]) {
    [[NSUserDefaults standardUserDefaults]
        setObject:[@"~/Documents/notes" stringByExpandingTildeInPath]
           forKey:@"NotesDirectory"];
    [[NSUserDefaults standardUserDefaults] synchronize];
  }

  [self loadNotes];
}

- (void)setupUserInterface {
  NSView *contentView = self.window.contentView;
  if (!contentView) {
    contentView = [[NSView alloc] initWithFrame:self.window.contentView.frame];
    self.window.contentView = contentView;
  }

  // 1. Search Field (Input)
  self.inputField = [[NSSearchField alloc] init];
  self.inputField.placeholderString = @"Search...";
  self.inputField.translatesAutoresizingMaskIntoConstraints = NO;
  self.inputField.delegate = self; // Fix: Set delegate
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
      NSTableViewFirstColumnOnlyAutoresizingStyle;
  self.tableView.style = NSTableViewStylePlain;       // Remove rounded corners
  self.tableView.intercellSpacing = NSMakeSize(0, 0); // Remove spacing
  self.tableView.rowHeight =
      20; // Adjust row height for better vertical centering

  // Create paragraph style for header indentation
  NSMutableParagraphStyle *headerStyle = [[NSMutableParagraphStyle alloc] init];
  [headerStyle setFirstLineHeadIndent:8.0];

  // Column 1: Name
  NSTableColumn *nameCol = [[NSTableColumn alloc] initWithIdentifier:@"Name"];
  nameCol.width = 200;
  NSAttributedString *nameTitle = [[NSAttributedString alloc]
      initWithString:@"Name"
          attributes:@{NSParagraphStyleAttributeName : headerStyle}];
  [nameCol.headerCell setAttributedStringValue:nameTitle];
  [self.tableView addTableColumn:nameCol];

  // Column 2: Date Modified
  NSTableColumn *dateCol = [[NSTableColumn alloc] initWithIdentifier:@"Date"];
  dateCol.width = 150;
  NSAttributedString *dateTitle = [[NSAttributedString alloc]
      initWithString:@"Date Modified"
          attributes:@{NSParagraphStyleAttributeName : headerStyle}];
  [dateCol.headerCell setAttributedStringValue:dateTitle];
  [self.tableView addTableColumn:dateCol];

  // Setup date formatter
  self.dateFormatter = [[NSDateFormatter alloc] init];
  [self.dateFormatter setDateFormat:@"dd MMM yyyy 'at' HH:mm"];

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

  // UI Polish: Font, Padding, Undo
  [self.textView
      setFont:[NSFont systemFontOfSize:[NSFont systemFontSize] + 2.0]];
  [self.textView setTextContainerInset:NSMakeSize(5, 5)];
  [self.textView setAllowsUndo:YES];

  textScrollView.documentView = self.textView;

  // Empty state label
  self.emptyStateLabel = [[NSTextField alloc] initWithFrame:NSZeroRect];
  [self.emptyStateLabel setStringValue:@"No note selected"];
  [self.emptyStateLabel setBezeled:NO];
  [self.emptyStateLabel setDrawsBackground:NO];
  [self.emptyStateLabel setEditable:NO];
  [self.emptyStateLabel setSelectable:NO];
  [self.emptyStateLabel setAlignment:NSTextAlignmentCenter];
  [self.emptyStateLabel setTextColor:[NSColor colorWithWhite:0.7 alpha:1.0]];
  [self.emptyStateLabel
      setFont:[NSFont systemFontOfSize:[NSFont systemFontSize] + 4.0]];
  [self.emptyStateLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
  [textScrollView addSubview:self.emptyStateLabel];

  // Center the empty state label
  [NSLayoutConstraint activateConstraints:@[
    [self.emptyStateLabel.centerXAnchor
        constraintEqualToAnchor:textScrollView.centerXAnchor],
    [self.emptyStateLabel.centerYAnchor
        constraintEqualToAnchor:textScrollView.centerYAnchor],
    [self.emptyStateLabel.widthAnchor constraintEqualToConstant:300]
  ]];

  // 4. Split View
  self.splitView =
      [[NSSplitView alloc] initWithFrame:NSMakeRect(0, 0, 400, 450)];
  self.splitView.dividerStyle =
      NSSplitViewDividerStylePaneSplitter; // Thicker divider
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

  // Force table to size its columns properly
  [self.tableView sizeToFit];

  // Set the initial position of the dividerrectly
  [self.splitView setPosition:150 ofDividerAtIndex:0];

  // Configure Key View Loop
  [self.inputField setNextKeyView:self.textView];
  [self.textView setNextKeyView:self.inputField];

  // Set initial focus
  [self.window makeFirstResponder:self.inputField];
}

- (void)loadNotes {
  NSString *path =
      [[NSUserDefaults standardUserDefaults] stringForKey:@"NotesDirectory"];

  dispatch_async(
      dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray *notes = [NSMutableArray array];
        NSFileManager *fm = [NSFileManager defaultManager];
        NSArray *files = [fm contentsOfDirectoryAtPath:path error:nil];

        for (NSString *file in files) {
          if ([file.pathExtension isEqualToString:@"txt"]) {
            NSString *fullPath = [path stringByAppendingPathComponent:file];
            Note *note = [[Note alloc] initWithFilePath:fullPath];
            [notes addObject:note];
          }
        }

        dispatch_async(dispatch_get_main_queue(), ^{
          self.allNotes = notes;
          self.filteredNotes = notes;
          [self.tableView reloadData];
        });
      });
}

- (void)controlTextDidChange:(NSNotification *)obj {
  NSString *searchString = [self.inputField stringValue];

  if (searchString.length == 0) {
    self.filteredNotes = self.allNotes;
  } else {
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(
                                              Note *evaluatedObject,
                                              NSDictionary *bindings) {
      return ([evaluatedObject.name rangeOfString:searchString
                                          options:NSCaseInsensitiveSearch]
                  .location != NSNotFound) ||
             ([evaluatedObject.content rangeOfString:searchString
                                             options:NSCaseInsensitiveSearch]
                  .location != NSNotFound);
    }];
    self.filteredNotes = [self.allNotes filteredArrayUsingPredicate:predicate];
  }

  [self.tableView reloadData];

  // If we have results, select the first one automatically (optional, but nice
  // for NV feel)
  if (self.filteredNotes.count > 0) {
    self.isUpdatingSearchProgrammatically = YES;
    [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0]
                byExtendingSelection:NO];
    self.isUpdatingSearchProgrammatically = NO;

    // Manually load the first note's content since selection change won't
    // update search field
    Note *firstNote = self.filteredNotes[0];
    self.currentNote = firstNote;
    [self.textView setString:firstNote.content];
    [self.emptyStateLabel setHidden:YES];
  }
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
  NSInteger row = [self.tableView selectedRow];
  if (row >= 0 && row < self.filteredNotes.count) {
    Note *note = self.filteredNotes[row];
    self.currentNote = note;
    [self.textView setString:note.content];
    [self.emptyStateLabel setHidden:YES];

    // Sync search field with note name (but not during programmatic selection
    // from search)
    if (!self.isUpdatingSearchProgrammatically) {
      [self.inputField setStringValue:note.name];
    }
  } else {
    self.currentNote = nil;
    [self.textView setString:@""];
    [self.emptyStateLabel setHidden:NO];
  }
}

- (void)showPreferences:(id)sender {
  [[SettingsWindowController sharedSettingsController] showSettings:sender];
}

- (void)focusSearch:(id)sender {
  [self.window makeFirstResponder:self.inputField];
}

- (void)textDidChange:(NSNotification *)notification {
  // Cancel existing timer
  [self.saveTimer invalidate];

  // Schedule save after 0.5 seconds of inactivity
  self.saveTimer =
      [NSTimer scheduledTimerWithTimeInterval:0.5
                                       target:self
                                     selector:@selector(saveCurrentNote)
                                     userInfo:nil
                                      repeats:NO];
}

- (void)saveCurrentNote {
  if (!self.currentNote)
    return;

  NSString *content = [self.textView string];
  NSError *error = nil;

  // Update note content in memory
  self.currentNote.content = content;

  // Write to file
  [content writeToFile:self.currentNote.filePath
            atomically:YES
              encoding:NSUTF8StringEncoding
                 error:&error];

  if (error) {
    NSLog(@"Error saving note: %@", error);
  }
}

- (void)deleteNote:(id)sender {
  if (!self.currentNote)
    return;

  NSAlert *alert = [[NSAlert alloc] init];
  [alert setMessageText:@"Delete Note?"];
  [alert setInformativeText:
             [NSString stringWithFormat:@"Are you sure you want to delete "
                                        @"\"%@\"? This cannot be undone.",
                                        self.currentNote.name]];
  [alert addButtonWithTitle:@"Delete"];
  [alert addButtonWithTitle:@"Cancel"];
  [alert setAlertStyle:NSAlertStyleCritical];

  [alert
      beginSheetModalForWindow:self.window
             completionHandler:^(NSModalResponse returnCode) {
               if (returnCode == NSAlertFirstButtonReturn) {
                 // User clicked Delete
                 NSError *error = nil;
                 [[NSFileManager defaultManager]
                     removeItemAtPath:self.currentNote.filePath
                                error:&error];

                 if (error) {
                   NSAlert *errorAlert = [[NSAlert alloc] init];
                   [errorAlert setMessageText:@"Error Deleting Note"];
                   [errorAlert setInformativeText:[error localizedDescription]];
                   [errorAlert runModal];
                 } else {
                   // Remove from arrays
                   NSMutableArray *updatedAllNotes =
                       [self.allNotes mutableCopy];
                   [updatedAllNotes removeObject:self.currentNote];
                   self.allNotes = updatedAllNotes;

                   NSMutableArray *updatedFilteredNotes =
                       [self.filteredNotes mutableCopy];
                   [updatedFilteredNotes removeObject:self.currentNote];
                   self.filteredNotes = updatedFilteredNotes;

                   // Update UI
                   self.currentNote = nil;
                   [self.textView setString:@""];
                   [self.tableView reloadData];

                   // Try to select the next note or previous note
                   if (self.filteredNotes.count > 0) {
                     [self.tableView
                             selectRowIndexes:[NSIndexSet indexSetWithIndex:0]
                         byExtendingSelection:NO];
                   } else {
                     [self.emptyStateLabel setHidden:NO];
                   }
                 }
               }
             }];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:
    (NSApplication *)sender {
  return YES;
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
  return self.filteredNotes.count;
}

- (id)tableView:(NSTableView *)tableView
    objectValueForTableColumn:(NSTableColumn *)tableColumn
                          row:(NSInteger)row {
  Note *note = self.filteredNotes[row];
  if ([tableColumn.identifier isEqualToString:@"Name"]) {
    return note.name;
  } else {
    return [self.dateFormatter stringFromDate:note.dateModified];
  }
}

- (NSView *)tableView:(NSTableView *)tableView
    viewForTableColumn:(NSTableColumn *)tableColumn
                   row:(NSInteger)row {
  NSView *containerView =
      [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];

  if (containerView == nil) {
    containerView = [[NSView alloc] initWithFrame:NSZeroRect];
    containerView.identifier = tableColumn.identifier;

    NSTextField *textField = [[NSTextField alloc] initWithFrame:NSZeroRect];
    textField.bordered = NO;
    textField.backgroundColor = [NSColor clearColor];
    textField.editable = NO;
    textField.selectable = NO;
    textField.translatesAutoresizingMaskIntoConstraints = NO;
    [[textField cell] setLineBreakMode:NSLineBreakByTruncatingTail];
    [textField setMaximumNumberOfLines:1];
    [containerView addSubview:textField];

    // Add constraints for padding
    [NSLayoutConstraint activateConstraints:@[
      [textField.leadingAnchor
          constraintEqualToAnchor:containerView.leadingAnchor
                         constant:8],
      [textField.trailingAnchor
          constraintEqualToAnchor:containerView.trailingAnchor
                         constant:-8],
      [textField.centerYAnchor
          constraintEqualToAnchor:containerView.centerYAnchor]
    ]];
  }

  NSTextField *textField = (NSTextField *)containerView.subviews.firstObject;
  Note *note = self.filteredNotes[row];
  if ([tableColumn.identifier isEqualToString:@"Name"]) {
    textField.stringValue = note.name;
  } else {
    textField.stringValue =
        [self.dateFormatter stringFromDate:note.dateModified];
  }

  return containerView;
}

- (BOOL)control:(NSControl *)control
               textView:(NSTextView *)textView
    doCommandBySelector:(SEL)commandSelector {
  if (control == self.inputField) {
    if (commandSelector == @selector(moveDown:)) {
      // Move focus to table view and select first row if possible
      [self.window makeFirstResponder:self.tableView];
      if (self.tableView.numberOfRows > 0) {
        [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0]
                    byExtendingSelection:NO];
      }
      return YES;
    } else if (commandSelector == @selector(insertNewline:)) {
      if (self.filteredNotes.count > 0) {
        // If results exist, select the first one and focus the editor
        [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0]
                    byExtendingSelection:NO];
        [self.window makeFirstResponder:self.textView];
        return YES;
      } else {
        // Create new note if no results
        NSString *noteName = [self.inputField stringValue];
        if (noteName.length > 0) {
          [self createNoteWithName:noteName];
        }
        return YES;
      }
    }
  }
  return NO;
}

- (void)createNoteWithName:(NSString *)name {
  NSString *notesDir =
      [[NSUserDefaults standardUserDefaults] stringForKey:@"NotesDirectory"];
  NSString *filePath = [notesDir
      stringByAppendingPathComponent:[NSString
                                         stringWithFormat:@"%@.txt", name]];

  // Create empty file
  [@"" writeToFile:filePath
        atomically:YES
          encoding:NSUTF8StringEncoding
             error:nil];

  // Create Note object
  Note *newNote = [[Note alloc] initWithFilePath:filePath];

  // Add to allNotes
  NSMutableArray *updatedNotes = [self.allNotes mutableCopy];
  [updatedNotes addObject:newNote];
  self.allNotes = updatedNotes;

  // Update filtered notes to include the new note
  self.filteredNotes = @[ newNote ];

  // Reload table and select the new note
  [self.tableView reloadData];
  [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0]
              byExtendingSelection:NO];

  // Focus the editor
  [self.window makeFirstResponder:self.textView];
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
