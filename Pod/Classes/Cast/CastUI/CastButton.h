//
//  CastButton.h
//
//  Created by Fabien BOURDON on 30/06/2014.
//  Copyright (c) 2014 Rémi ROCARIES. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CastButton : UIButton

@property (nonatomic, retain) NSString *mainTitle;
@property (nonatomic, retain) NSString *subTitle;
@property (nonatomic, retain) UILabel *subLabel;

- (void) compile;


@end
