//
//  ImageUtils.h
//  VODE Orange
//
//  Created by Fabien BOURDON on 13/02/2014.
//  Copyright (c) 2014 Labgency. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ImageUtils : NSObject

+ (UIImage *)getRectImageWithColor:(UIColor *)color withSize:(CGSize)size;

+ (UIImage *)getTransverseBarImageWithColor:(UIColor *)color withSize:(CGSize)size;

@end
