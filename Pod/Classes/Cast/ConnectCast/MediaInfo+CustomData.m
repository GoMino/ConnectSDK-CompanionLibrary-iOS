#import "MediaInfo+CustomData.h"
#import <objc/runtime.h>

@implementation MediaInfo (CustomData)

- (NSDictionary*) customData {
    return objc_getAssociatedObject(self, @selector(customData));
}

- (void)setCustomData: (NSDictionary*) dict {
    objc_setAssociatedObject(self, @selector(customData), dict, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSDictionary*) customDataForLoad {
    return objc_getAssociatedObject(self, @selector(customDataForLoad));
}

- (void)setCustomDataForLoad: (NSDictionary*) dict {
    objc_setAssociatedObject(self, @selector(customDataForLoad), dict, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
