#import <Foundation/Foundation.h>

@interface Note : NSObject

@property(strong, nonatomic) NSString *name;
@property(strong, nonatomic) NSString *content;
@property(strong, nonatomic) NSString *filePath;
@property(strong, nonatomic) NSDate *dateModified;

- (instancetype)initWithFilePath:(NSString *)path;

@end
