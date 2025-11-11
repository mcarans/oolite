// NSUserDefaults+Override.h
#import <Foundation/NSUserDefaults.h>

@interface NSUserDefaults (Override)

- (BOOL) writeDictionary: (NSDictionary*)dict
                  toFile: (NSString*)file;

@end
