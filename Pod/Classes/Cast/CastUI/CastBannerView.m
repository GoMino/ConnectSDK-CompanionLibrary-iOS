//
//  CastBannerView.m
//
//  Created by Fabien BOURDON on 03/07/2014.
//  Copyright (c) 2014 Rémi ROCARIES. All rights reserved.
//

#import "CastBannerView.h"
#import "AsyncImageView.h"

@interface CastBannerView ()

@property (retain, nonatomic) IBOutlet UIImageView *mediaImageView;
@property (retain, nonatomic) IBOutlet UILabel *mediaTitleLabel;
@property (retain, nonatomic) IBOutlet UILabel *mediaSubtitleLabel;
@property (retain, nonatomic) IBOutlet UIButton *playButton;


@end


@implementation CastBannerView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

+ (CastBannerView *)getView{
    //NSBundle *bundle = [NSBundle mainBundle];
    //NSBundle *bundle = [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"ConnectSDK-CompanionLibrary-iOS" ofType:@"bundle"]];
    NSBundle *bundle = [NSBundle bundleWithURL:[[NSBundle bundleForClass:[self class]] URLForResource:@"ConnectSDK-CompanionLibrary-iOS" withExtension:@"bundle"]];
    CastBannerView *view = [[bundle loadNibNamed:@"CastBannerView" owner:nil options:nil] lastObject];
    return view;
}


- (void)awakeFromNib{
    [super awakeFromNib];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(openDetail)];
    [self addGestureRecognizer:tap];
}

- (void) updateContentTitle:(NSString *)title subtitle:(NSString *)subtitle image:(UIImage *)image withPlayingState:(BOOL)play{
    self.mediaImageView.image = image;
    self.mediaSubtitleLabel.text = subtitle;
    self.mediaTitleLabel.text = title;
    self.playButton.selected = !play;
}

- (void) updateContentTitle:(NSString *)title subtitle:(NSString *)subtitle imageUrl:(NSURL *)imageUrl withPlayingState:(BOOL)play{
    self.mediaSubtitleLabel.text = subtitle;
    self.mediaTitleLabel.text = title;
    self.playButton.selected = !play;
    self.mediaImageView.imageURL = imageUrl;
}

- (IBAction)playActtion:(id)sender {
    self.playButton.selected = !self.playButton.selected;
    if(self.delegate && [self.delegate respondsToSelector:@selector(castBannerViewTapOnPlay)]){
        [self.delegate castBannerViewTapOnPlay];
    }
}

- (void)openDetail{
    if(self.delegate && [self.delegate respondsToSelector:@selector(castBannerViewTapOpenDetail)]){
        [self.delegate castBannerViewTapOpenDetail];
    }
}


- (void)dealloc {
    [_playButton release];
    [super dealloc];
}
@end
