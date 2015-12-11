//
//  CastDeviceSelectionView.h
//
//  Created by Fabien BOURDON on 30/06/2014.
//  Copyright (c) 2014 Rémi ROCARIES. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CastButton.h"

@protocol CastDeviceSelectionDelegate <NSObject>

@required
- (void) castDeviceSelectionViewDidCancel;
- (void) castDeviceSelectionViewDidSelectIndex:(int)index;

@end

@interface CastDeviceSelectionView : UIView

@property (nonatomic, assign)id<CastDeviceSelectionDelegate>delegate;


- (void) addButton:(CastButton *)button;
- (void) compile;


@end
