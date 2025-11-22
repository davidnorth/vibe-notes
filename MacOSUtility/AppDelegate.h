#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate, NSTableViewDataSource,
                                   NSTableViewDelegate, NSSplitViewDelegate>

@property(strong, nonatomic) NSWindow *window;
@property(strong) NSSearchField *inputField;
@property(strong) NSSplitView *splitView;
@property(strong) NSTableView *tableView;
@property(strong) NSTextView *textView;

@property(strong) NSArray *allNotes;
@property(strong) NSArray *filteredNotes;

- (void)setupMenu;

@end
