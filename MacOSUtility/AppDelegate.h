#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate, NSTableViewDataSource,
                                   NSTableViewDelegate, NSSplitViewDelegate>

@property(strong, nonatomic) NSWindow *window;
@property(strong, nonatomic) NSSearchField *inputField;
@property(strong, nonatomic) NSSplitView *splitView;
@property(strong, nonatomic) NSTableView *tableView;
@property(strong, nonatomic) NSTextView *textView;

@end
