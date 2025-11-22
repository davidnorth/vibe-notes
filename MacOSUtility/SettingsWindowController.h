#import <Cocoa/Cocoa.h>

@interface SettingsWindowController : NSWindowController <NSWindowDelegate>

@property(strong, nonatomic) NSPopUpButton *pathPopUp;

+ (instancetype)sharedSettingsController;
- (void)showSettings:(id)sender;

@end
