//
//  CastButton.m
//
//  Created by Fabien BOURDON on 30/06/2014.
//  Copyright (c) 2014 Rémi ROCARIES. All rights reserved.
//

#import "CastButton.h"

@implementation CastButton

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)compile{
    self.titleLabel.textColor = [UIColor whiteColor];
    
    [self setBackgroundColor:[UIColor colorWithRed:112.0f/255.0f green:112.0f/255.0f blue:112.0f/255.0f alpha:1.0f]];
    [self.titleLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:17.0f]];
    self.titleLabel.textColor = [UIColor whiteColor];
    
    if(self.mainTitle==nil && self.subTitle==nil){
        [self setTitle:@"Chromecast" forState:UIControlStateNormal];
    }else{
        if(self.mainTitle){
            [self setTitle:self.mainTitle forState:UIControlStateNormal];
            
        }
        if(self.subTitle){
            self.subLabel = [[[UILabel alloc]initWithFrame:CGRectMake(10,ceilf(self.frame.size.height/2),self.frame.size.width-20,20)]autorelease];
            self.subLabel.text = self.subTitle;
            self.subLabel.backgroundColor = [UIColor clearColor];
            self.subLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:12.0f];
            //self.subLabel.textColor = [UIColor orangeGray142TextColor];
            [self addSubview:self.subLabel];
            [self setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
            [self setTitleEdgeInsets:UIEdgeInsetsMake(0,10,18, 10)];
        }
    }
}


@end
