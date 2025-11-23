#import "Note.h"

@implementation Note

- (instancetype)initWithFilePath:(NSString *)path {
  self = [super init];
  if (self) {
    _filePath = path;
    _name = [[path lastPathComponent] stringByDeletingPathExtension];

    NSError *error = nil;
    _content = [NSString stringWithContentsOfFile:path
                                         encoding:NSUTF8StringEncoding
                                            error:&error];

    if (!_content) {
      // Fallback to MacOS Roman if UTF8 fails
      _content = [NSString stringWithContentsOfFile:path
                                           encoding:NSMacOSRomanStringEncoding
                                              error:nil];
    }

    if (!_content) {
      _content = @"";
    }

    NSDictionary *attrs =
        [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
    _dateModified = [attrs fileModificationDate];
  }
  return self;
}

@end
