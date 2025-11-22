#import <Cocoa/Cocoa.h>

@class Note;

@interface AppDelegate
    : NSObject <NSApplicationDelegate, NSTableViewDataSource,
                NSTableViewDelegate, NSSplitViewDelegate, NSSearchFieldDelegate>

@property(strong, nonatomic) NSWindow *window;
@property(strong) NSSearchField *inputField;
@property(strong) NSSplitView *splitView;
@property(strong) NSTableView *tableView;
@property(strong) NSTextView *textView;

@property(strong) NSArray *allNotes;
@property(strong) NSArray *filteredNotes;

@property(nonatomic) BOOL isUpdatingSearchProgrammatically;
@property(strong) NSTextField *emptyStateLabel;
@property(strong) NSTimer *saveTimer;
@property(strong) Note *currentNote;
@property(strong) NSDateFormatter *dateFormatter;

- (void)setupMenu;

@end
