//
//  CastViewController.m
//
//  Created by Fabien BOURDON on 07/07/2014.
//  Copyright (c) 2014 Rémi ROCARIES. All rights reserved.
//

#import "CastViewController.h"
#import "ConnectCastManager.h"
#import "AsyncImageView.h"
#import "Masonry.h"
#import "ImageUtils.h"

@interface CastViewController ()

@property (retain, nonatomic) IBOutlet UIImageView *thumbnail;
@property (retain, nonatomic) IBOutlet UILabel *titleLabel;
@property (retain, nonatomic) IBOutlet UILabel *subtitleLabel;
@property (retain, nonatomic) IBOutlet UIButton *playButton;
@property (retain, nonatomic) IBOutlet UIButton *stopButton;
@property (retain, nonatomic) IBOutlet UISlider *positionSlider;
@property (retain, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (retain, nonatomic) IBOutlet UILabel *timerPosition;
@property (retain, nonatomic) IBOutlet UILabel *durationPosition;
@property (retain, nonatomic) IBOutlet UILabel *chromeState;
@property (retain, nonatomic) IBOutlet UIButton *backButton;

@property (retain, nonatomic) NSString * movieTitle;
@property (retain, nonatomic) NSString * movieSubTitle;
//@property (retain, nonatomic) UIImage * movieImage;
@property (nonatomic, assign) CGFloat currentvolume;

@property (nonatomic, retain) NSTimer *timer;

@property (nonatomic, assign) BOOL isUpdatePerform;

@end

@implementation CastViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.spinner.hidden = YES;
    
    self.subtitleLabel.text = self.movieSubTitle;
    self.titleLabel.text = self.movieTitle;
    //self.thumbnail.image = self.movieImage;
    self.backButton.hidden = NO;
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(addListener) name:NOTIFICATION_CAST_CONNECT object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(removeListener) name:NOTIFICATION_CAST_DISCONNECT object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(updateControl) name:NOTIFICATION_CAST_MEDIA_STATUS_CHANGE object:nil];
    
    UIButton *button = [[ConnectCastManager getInstance] castButtonForPlayers];
    
    if(castToButton!=nil){
        [castToButton addSubview:button];
        [button mas_makeConstraints:^(MASConstraintMaker *make) {
            // All edges should equal those of the superview
            make.edges.equalTo(castToButton);
        }];
    }
    
    UIButton *btnTracks = [[ConnectCastManager getInstance] castTrackButton];
    [btnTracks removeFromSuperview];
    if(castTracksButton!=nil){
        [castTracksButton addSubview:btnTracks];
        [btnTracks mas_makeConstraints:^(MASConstraintMaker *make) {
            // All edges should equal those of the superview
            make.edges.equalTo(castTracksButton);
        }];
    }
    
    [progressVolume setShowsRouteButton:NO];
    [progressVolume setMaximumVolumeSliderImage:[ImageUtils getRectImageWithColor:[UIColor blackColor] withSize:CGSizeMake(1,2)] forState:UIControlStateNormal];
    [progressVolume setMinimumVolumeSliderImage:[ImageUtils getRectImageWithColor:[UIColor whiteColor] withSize:CGSizeMake(1,2)] forState:UIControlStateNormal];
    //[progressSlider setMaximumTrackImage:[UIImage imageNamed:@"progress_moviebar_max"] forState:UIControlStateNormal];
    [self.positionSlider setMaximumTrackImage:[ImageUtils getRectImageWithColor:[UIColor blackColor] withSize:CGSizeMake(1,2)] forState:UIControlStateNormal];
}


- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    [self startAutoUpdate];
}

- (void)viewWillDisappear:(BOOL)animated{
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    [[NSNotificationCenter defaultCenter]removeObserver:self];
    [self stopAutoUpdate];
    [self.timer invalidate];
    [super viewWillDisappear:animated];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (BOOL)shouldAutorotate
{
    return YES;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return UIInterfaceOrientationIsLandscape(toInterfaceOrientation);
}

- (UIInterfaceOrientationMask) supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskLandscape;
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

#pragma mark - implementation

- (void)configureWithImage:(UIImage *)image andTitle:(NSString *)title subtitle:(NSString *)subtitle{
    self.thumbnail.image = image;
    self.movieTitle = title;
    self.movieSubTitle = subtitle;
    self.currentvolume = [[ConnectCastManager getInstance]deviceVolume];
}

- (void)configureWithImageUrl:(NSURL *)imageUrl andTitle:(NSString *)title subtitle:(NSString *)subtitle
{
    self.movieTitle = title;
    self.movieSubTitle = subtitle;
    self.currentvolume = [[ConnectCastManager getInstance]deviceVolume];
    self.thumbnail.imageURL = imageUrl;
    
    //    UIImage* mediaImg = [[AsyncImageLoader sharedLoader].cache objectForKey:imageUrl];
    //    if(mediaImg == nil){
    //        dispatch_queue_t imageQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH,  0ul);
    //        dispatch_async(imageQueue, ^{
    //            NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:[imageUrl absoluteString]]];
    //            dispatch_async(dispatch_get_main_queue(), ^{
    //                self.movieImage.image = [UIImage imageWithData:data];
    //            });
    //
    //        });
    //        
    //    }

}


- (void)startAutoUpdate{
    if(!self.timer.isValid){
        NSLog(@"startAutoUpdate restart timer");
        [self.timer invalidate];
        self.timer = [NSTimer scheduledTimerWithTimeInterval:1.f target:self selector:@selector(update) userInfo:nil repeats:YES];
        [self.timer fire];
    }
    
}

- (void)stopAutoUpdate{
    NSLog(@"stopAutoUpdate");
    if(self.timer){
        [self.timer invalidate];
    }
}

- (NSString *)playedTimeTextForSec:(int)timeInsecondes
{
    int remainingSecondes = timeInsecondes;
    int hours = remainingSecondes / 3600;
    int minutes = 0;
    int secondes = 0;
    
    int secondsAfterHours = remainingSecondes % 3600;
    
    if (secondsAfterHours >= 60)
        minutes = secondsAfterHours / 60;
    
    secondes = secondsAfterHours % 60;
    
    return [NSString stringWithFormat:@"%02i:%02i:%02i", hours, minutes, secondes];
}


- (void) setupImageForImageUrl:(NSString *) stringUrl imageView:(UIImageView *) imageView defaultImage:(UIImage *) defaultImage {
    dispatch_async( dispatch_get_main_queue(), ^{
        //[imageView cancelLoadingImagesForTarget];
        
        
        NSURL *url = [imageView imageURL];
        if (url) {
            
            if ([imageView.imageURL.absoluteString isEqualToString:stringUrl] == NO) {
                // cancel previous loading
                [[AsyncImageLoader sharedLoader] cancelLoadingURL:url];
            }
        }
        
        //    if ([imageView isKindOfClass:[AsyncImageView class]]) {
        //        imageView.crossfadeDuration = .0f;
        //    }
        
        
        if (defaultImage)
            [imageView setImage:defaultImage];
        else {
            //NSLog(@"NO DEF IMG");
        }
        [imageView setImageURL:[NSURL  URLWithString:stringUrl]];
    });
}


- (void)update{
        if(!self.isUpdatePerform){
            self.isUpdatePerform = YES;
            [[ConnectCastManager getInstance] updateStatsFromDevice];
            
            self.positionSlider.enabled = YES;
            self.timerPosition.text = [self playedTimeTextForSec:[[ConnectCastManager getInstance]mediaPosition]];
            self.durationPosition.text = [self playedTimeTextForSec:[[ConnectCastManager getInstance]mediaDuration]];
            
            [self.positionSlider setMinimumValue:0.f];
            [self.positionSlider setMaximumValue:[[ConnectCastManager getInstance] mediaDuration]];
            if(!_positionSlider.isTracking){
                [self.positionSlider setValue:[[ConnectCastManager getInstance] mediaPosition] animated:YES];
            }
            
            if([[ConnectCastManager getInstance] hasMediaInformation])
            {
                if([[ConnectCastManager getInstance] getMediaInfoImages] != nil){
                    if([[ConnectCastManager getInstance] getMediaInfoImages].count > 0)
                    {
                        ImageInfo *img =[[[ConnectCastManager getInstance] getMediaInfoImages] objectAtIndex:0];
                        self.thumbnail.imageURL = img.url;
                    }
                    self.movieTitle = [[ConnectCastManager getInstance] getMediaInfoTitle];
                    if(self.movieTitle == nil){
                        self.movieTitle = @"";
                    }
                    self.movieSubTitle = [[ConnectCastManager getInstance] getMediaInfoSubTitle];
                    if(self.movieSubTitle == nil){
                        self.movieSubTitle = @"";
                    }
                }
            }
            
            int state = [[ConnectCastManager getInstance] playerState];
            switch (state) {
                case MediaControlPlayStateUnknown:
                    self.playButton.enabled = NO;
                    self.spinner.hidden = NO;
                    self.positionSlider.enabled = NO;
                    [self.spinner startAnimating];
                    self.chromeState.text = [NSString stringWithFormat:@"En attente d'informations de %@",[[ConnectCastManager getInstance]getDeviceName]];
                    break;
                case MediaControlPlayStateIdle:
                    self.playButton.selected = YES;
                    self.playButton.enabled = NO;
                    self.positionSlider.enabled = NO;
                    [self.spinner stopAnimating];
                    self.chromeState.text = @"Arrêt de la lecture";
                    break;
                case MediaControlPlayStateBuffering:
                    self.playButton.selected = YES;
                    self.playButton.enabled = NO;
                    self.positionSlider.enabled = NO;
                    self.spinner.hidden = NO;
                    [self.spinner startAnimating];
                    self.chromeState.text = @"Chargement";
                    break;
                case MediaControlPlayStatePlaying:
                    self.playButton.enabled = YES;
                    self.playButton.selected = NO;
                    self.positionSlider.enabled = YES;
                    self.spinner.hidden = YES;
                    [self.spinner stopAnimating];
                    self.chromeState.text = [NSString stringWithFormat:@"Lecture sur %@",[[ConnectCastManager getInstance]getDeviceName]];
                    break;
                case MediaControlPlayStatePaused:
                    self.playButton.enabled = YES;
                    self.playButton.selected = YES;
                    self.positionSlider.enabled = YES;
                    self.spinner.hidden = YES;
                    [self.spinner stopAnimating];
                    self.chromeState.text = @"Pause";
                    break;
                    
                case MediaControlPlayStateFinished:
                    [self stopAction:nil];
                    break;
                default:
                    break;
            }
            
            self.subtitleLabel.text = self.movieSubTitle;
            self.titleLabel.text = self.movieTitle;
            
            self.isUpdatePerform = NO;
        }
}



- (IBAction)playPush:(id)sender {
    if([[ConnectCastManager getInstance] isPlayingMedia]){
        [[ConnectCastManager getInstance]pauseCastMedia:YES];
    }else{
        [[ConnectCastManager getInstance]pauseCastMedia:NO];
    }
}

- (IBAction)closeAction{
    [self stopAutoUpdate];
    [[NSNotificationCenter defaultCenter]postNotificationName:NOTIFICATION_CAST_DISMISS_CONTROLLER object:nil];
}


- (IBAction)stopAction:(id)sender {
    [self stopAutoUpdate];
    self.playButton.enabled = NO;
    self.positionSlider.enabled = NO;
    [self.positionSlider setValue:0 animated:NO];
    [[ConnectCastManager getInstance] stopCastMedia];
    [[NSNotificationCenter defaultCenter]postNotificationName:NOTIFICATION_CAST_DISMISS_CONTROLLER object:nil];
}

- (void)updateControl{
    [self startAutoUpdate];
}

- (void)addListener{
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(updateControl) name:NOTIFICATION_CAST_MEDIA_STATUS_CHANGE object:nil];
}


- (void)removeListener{
    [[NSNotificationCenter defaultCenter]removeObserver:self name:NOTIFICATION_CAST_MEDIA_STATUS_CHANGE object:nil];
    [self closeAction];
}

- (IBAction)beginSeek:(id)sender {
    [self stopAutoUpdate];
}

- (IBAction)seekEnd:(id)sender {
    UISlider *slider = (UISlider *)sender;
    CGFloat percent = ((slider.value*100)/slider.maximumValue)/100;
    slider.enabled = NO;
    [[ConnectCastManager getInstance] setPlaybackPercent:percent];
    [self startAutoUpdate];
}

- (IBAction)seekEndOut:(id)sender {
    [self startAutoUpdate];
}

- (IBAction)seekToPosition:(id)sender {
    
}

- (IBAction)backwardPushed:(id)sender {
    double currentTime = [ConnectCastManager getInstance].mediaPosition;
    float newPosition = currentTime - 30;
    [[ConnectCastManager getInstance] setPlaybackPosition:newPosition];
}


- (void)dealloc {
    self.thumbnail = nil;
    self.titleLabel = nil;
    self.subtitleLabel = nil;
    self.playButton = nil;
    self.stopButton = nil;
    self.positionSlider = nil;
    self.spinner = nil;
    self.timerPosition = nil;
    self.durationPosition = nil;
    self.chromeState = nil;
    self.backButton = nil;
    self.movieTitle = nil;
    self.movieSubTitle = nil;
    self.timer = nil;
    [castToButton release];
    [castTracksButton release];
    [super dealloc];
}
@end
