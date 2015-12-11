//
//  ImageUtils.m
//  VODE Orange
//
//  Created by Fabien BOURDON on 13/02/2014.
//  Copyright (c) 2014 Labgency. All rights reserved.
//

#import "ImageUtils.h"

@implementation ImageUtils

+ (UIImage *)getRectImageWithColor:(UIColor *)color withSize:(CGSize)size{
    
    UIGraphicsBeginImageContext(size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    UIImage *image = nil;
    if(context){
        CGContextSetFillColorWithColor(context, color.CGColor);
        CGContextFillRect(context, (CGRect){.size = size});
        image = UIGraphicsGetImageFromCurrentImageContext();
    }
    UIGraphicsEndImageContext();
    return image;
}

+ (UIImage *)getTransverseBarImageWithColor:(UIColor *)color withSize:(CGSize)size{
    UIGraphicsBeginImageContext(size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    UIImage *image = nil;
    if(context){
        CGContextSetLineWidth(context,2);
        CGContextSetStrokeColorWithColor(context, color.CGColor);
        
        
        CGContextMoveToPoint(context, 0,0);
        CGContextMoveToPoint(context, size.width-1,0);
        CGContextAddLineToPoint(context,size.width,0);
        CGContextAddLineToPoint(context,size.width,1);
        CGContextAddLineToPoint(context,1,size.height);
        CGContextAddLineToPoint(context,0,size.height);
        CGContextAddLineToPoint(context,0,size.height-1);
        CGContextMoveToPoint(context, size.width-1,0);
        
        CGContextSetShouldAntialias(context, YES);
        CGContextSetAllowsAntialiasing(context, YES);
        CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
        
        CGContextSetFillColorWithColor(context, color.CGColor);
        CGContextFillPath(context);
        
        
        image = UIGraphicsGetImageFromCurrentImageContext();
    }
    UIGraphicsEndImageContext();
    return image;
}

@end
