//
//  ChromeCastAlertView.h
//  OCS GO
//
//  Created by Fabien BOURDON on 03/07/2014.
//  Copyright (c) 2014 Rémi ROCARIES. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CastAlertViewDelegate <NSObject>

- (void) castAlertViewClickToDisconnect;
- (void) castAlertViewClickToCancel;
- (void) castAlertViewClickTogglePlayPause;
- (void) castAlertViewClickGoToFullscreen;

@end



@interface CastAlertView : UIView
@property (retain, nonatomic) IBOutlet UIButton *disconnectButton;

@property (nonatomic, assign) id<CastAlertViewDelegate>delegate;

+ (CastAlertView *)getView;
- (void) updateContentDeviceName:(NSString *)name title:(NSString *)title subtitle:(NSString *)subtitle image:(UIImage *)image withPlayingState:(BOOL)play;
- (void) updateContentDeviceName:(NSString *)name title:(NSString *)title subtitle:(NSString *)subtitle imageUrl:(NSURL *)imageUrl withPlayingState:(BOOL)play;

@end
