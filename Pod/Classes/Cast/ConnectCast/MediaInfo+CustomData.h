#import <Foundation/Foundation.h>
#import "MediaInfo.h"

@interface MediaInfo (CustomData)

@property (nonatomic, retain) NSDictionary* customData;
@property (nonatomic, retain) NSDictionary* customDataForLoad;

@end
