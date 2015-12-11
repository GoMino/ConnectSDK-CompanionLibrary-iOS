//
//  CastViewController.h
//
//  Created by Fabien BOURDON on 07/07/2014.
//  Copyright (c) 2014 Rémi ROCARIES. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>


@interface CastViewController : UIViewController{
    IBOutlet MPVolumeView   *progressVolume;
    IBOutlet UIView *castToButton;
    IBOutlet UIView *castTracksButton;
}


//@property (nonatomic, assign) id<CastControlViewDelegate>delegate;


- (void) configureWithImage:(UIImage *)image andTitle:(NSString *)title subtitle:(NSString *)subtitle;
- (void) configureWithImageUrl:(NSURL *)imageUrl andTitle:(NSString *)title subtitle:(NSString *)subtitle;

@end
