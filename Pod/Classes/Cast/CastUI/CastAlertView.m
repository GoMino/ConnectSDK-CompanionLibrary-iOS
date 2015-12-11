//
//  ChromeCastAlertView.m
//  OCS GO
//
//  Created by Fabien BOURDON on 03/07/2014.
//  Copyright (c) 2014 Rémi ROCARIES. All rights reserved.
//

#import "CastAlertView.h"
#import "AsyncImageView.h"


@interface CastAlertView ()

@property (retain, nonatomic) IBOutlet UILabel *deviceName;
@property (retain, nonatomic) IBOutlet UIImageView *mediaImageView;
@property (retain, nonatomic) IBOutlet UILabel *mediaTitleLabel;
@property (retain, nonatomic) IBOutlet UILabel *mediaSubtitleLabel;
@property (retain, nonatomic) IBOutlet UILabel *noMediaPlayLabel;
@property (retain, nonatomic) IBOutlet UIView *backView;
@property (retain, nonatomic) IBOutlet UIButton *togglePlayPauseButton;
@property (retain, nonatomic) IBOutlet UIView *fullscreenTapZone;

@end

@implementation CastAlertView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

+ (CastAlertView *)getView{
    //NSBundle *bundle = [NSBundle mainBundle];
    //NSBundle *bundle = [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"ConnectSDK-CompanionLibrary-iOS" ofType:@"bundle"]];
    //NSBundle *bundle = [NSBundle bundleWithPath:[[NSBundle bundleForClass:[self class]]pathForResource:@"ConnectSDK-CompanionLibrary-iOS" ofType:@"bundle"]];
    NSBundle *bundle = [NSBundle bundleWithURL:[[NSBundle bundleForClass:[self class]] URLForResource:@"ConnectSDK-CompanionLibrary-iOS" withExtension:@"bundle"]];
    CastAlertView *view = [[bundle loadNibNamed:@"CastAlertView" owner:nil options:nil] lastObject];
    return view;
}


- (void)awakeFromNib{
    [super awakeFromNib];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(cancelAction:)];
    [self.backView addGestureRecognizer:tap];
    
    UITapGestureRecognizer *tapToFullscreen = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(goToFullScreenController)];
    [self.fullscreenTapZone addGestureRecognizer:tapToFullscreen];
    [self.fullscreenTapZone setUserInteractionEnabled:YES];
}

- (void) updateContentDeviceName:(NSString *)name title:(NSString *)title subtitle:(NSString *)subtitle image:(UIImage *)image withPlayingState:(BOOL)play{
    self.deviceName.text = name;
    if(title!=nil || subtitle!=nil || image !=nil){
        self.mediaTitleLabel.hidden = NO;
        self.mediaSubtitleLabel.hidden = NO;
        self.mediaImageView.hidden = NO;
        self.togglePlayPauseButton.hidden = NO;
        self.noMediaPlayLabel.hidden = YES;
        self.mediaImageView.image = image;
        self.mediaSubtitleLabel.text = subtitle;
        self.mediaTitleLabel.text = title;
        self.togglePlayPauseButton.selected = !play;
    }else{
        self.mediaTitleLabel.hidden = YES;
        self.mediaSubtitleLabel.hidden = YES;
        self.mediaImageView.hidden = YES;
        self.togglePlayPauseButton.hidden = YES;
        self.noMediaPlayLabel.hidden = NO;
    }
    
}

- (void) updateContentDeviceName:(NSString *)name title:(NSString *)title subtitle:(NSString *)subtitle imageUrl:(NSURL *)imageUrl withPlayingState:(BOOL)play{
    [self updateContentDeviceName:name title:title subtitle:subtitle image:nil withPlayingState:play];
    if(imageUrl !=nil){
        self.mediaImageView.hidden = NO;
        self.mediaImageView.imageURL = imageUrl;
    }else{
        self.mediaImageView.hidden = YES;
    }
}


- (IBAction)disconnectAction:(id)sender {
    if(self.delegate && [self.delegate respondsToSelector:@selector(castAlertViewClickToDisconnect)]){
        [self.delegate castAlertViewClickToDisconnect];
    }
}

- (IBAction)cancelAction:(id)sender {
    if(self.delegate && [self.delegate respondsToSelector:@selector(castAlertViewClickToCancel)]){
        [self.delegate castAlertViewClickToCancel];
    }
}

- (IBAction)togglePlayPause:(id)sender {
    self.togglePlayPauseButton.selected = !self.togglePlayPauseButton.selected;
    if(self.delegate && [self.delegate respondsToSelector:@selector(castAlertViewClickTogglePlayPause)]){
        [self.delegate castAlertViewClickTogglePlayPause];
    }
}

- (void) goToFullScreenController
{
    if(self.delegate && [self.delegate respondsToSelector:@selector(castAlertViewClickGoToFullscreen)]){
        [self.delegate castAlertViewClickGoToFullscreen];
    }
}

- (void)dealloc {
    [_deviceName release];
    [_mediaImageView release];
    [_mediaTitleLabel release];
    [_mediaSubtitleLabel release];
    [_noMediaPlayLabel release];
    [_backView release];
    [_togglePlayPauseButton release];
    [_fullscreenTapZone release];
    [_disconnectButton release];
    [super dealloc];
}
@end
