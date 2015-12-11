//
//  UINavigationController+LockableRotation.m
//  ConnectSDK-CompanionLibrary-iOS
//
//  Created by Amine Bezzarga on 12/10/15.
//  Copyright © 2015 Amine Bezzarga. All rights reserved.
//

#import "UINavigationController+LockableRotation.h"

@implementation UINavigationController (LockableRotation)

#pragma From UINavigationController

- (BOOL)shouldAutorotate {
    
    //return [self.visibleViewController shouldAutorotate];
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations {
    
    //return [self.visibleViewController supportedInterfaceOrientations];
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return [self.visibleViewController shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}

#pragma -

@end
