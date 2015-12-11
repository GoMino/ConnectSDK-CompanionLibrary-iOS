//
//  CastBannerView.h
//
//  Created by Fabien BOURDON on 03/07/2014.
//  Copyright (c) 2014 Rémi ROCARIES. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol CastBannerViewDelegate;
@interface CastBannerView : UIView


@property (nonatomic, assign) id<CastBannerViewDelegate>delegate;

+ (CastBannerView *)getView;
- (void) updateContentTitle:(NSString *)title subtitle:(NSString *)subtitle image:(UIImage *)image withPlayingState:(BOOL)play;
- (void) updateContentTitle:(NSString *)title subtitle:(NSString *)subtitle imageUrl:(NSURL *)imageUrl withPlayingState:(BOOL)play;

@end


@protocol CastBannerViewDelegate <NSObject>

- (void) castBannerViewTapOpenDetail;
- (void) castBannerViewTapOnPlay;

@end
