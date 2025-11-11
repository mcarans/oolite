// NSUserDefaults+Override.m
#import "NSUserDefaults+Override.h"
#import <Foundation/NSData.h>
#import <Foundation/NSFileManager.h>
#import <Foundation/NSPropertyList.h>

@implementation NSUserDefaults (Override)

- (BOOL) writeDictionary: (NSDictionary*)dict
                  toFile: (NSString*)file
{
  if ([file length] == 0)
    {
      NSLog(@"Defaults database filename is empty when writing");
    }
  else if (nil == dict)
    {
      NSFileManager	*mgr = [NSFileManager defaultManager];

      return [mgr removeFileAtPath: file handler: nil];
    }
  else
    {
      NSData	*data;
      NSString	*err;

      err = nil;
      data = [NSPropertyListSerialization dataFromPropertyList: dict
	       format: NSPropertyListOpenStepFormat
	       errorDescription: &err];
      if (data == nil)
	{
	  NSLog(@"Failed to serialize defaults database for writing: %@", err);
	}
      else if ([data writeToFile: file atomically: YES] == NO)
	{
	  NSLog(@"Failed to write defaults database to file: %@", file);
	}
      else
	{
	  return YES;
	}
    }
  return NO;
}

@end
