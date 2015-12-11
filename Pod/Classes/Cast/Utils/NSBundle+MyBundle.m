//
//  NSBundle+MyBundle.m
//  Pods
//
//  Created by Amine Bezzarga on 12/10/15.
//
//

#import "CastAlertView.h"
#import "NSBundle+MyBundle.h"

@implementation NSBundle (MYBundle)

+ (instancetype)MYBundle{
    //NSBundle *mainBundle = [NSBundle mainBundle];
    //NSURL *bundleUrl = [mainBundle URLForResource:@"ConnectSDK-CompanionLibrary-iOS" withExtension:@"framework"];
    NSURL* bundleUrl = [[NSBundle bundleForClass:[CastAlertView class]] URLForResource:@"ConnectSDK-CompanionLibrary-iOS" withExtension:@"bundle"];
    NSBundle *bundle = [NSBundle bundleWithURL:bundleUrl];
    return bundle;
}

+ (UIImage*)imageNamed:(NSString*)name{
    UIImage *image;
    
    image = [UIImage imageNamed:[NSString stringWithFormat:@"ConnectSDK-CompanionLibrary-iOS.bundle/%@",name]];
    if (image) {
        return image;
    }
    
    NSString* path = [[[NSBundle MYBundle] resourcePath] stringByAppendingPathComponent:name];
    image = [UIImage imageWithContentsOfFile:path];
    
    return image;
}
@end
