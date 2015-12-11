#import "ConnectCastManager.h"
#import <AVFoundation/AVAudioSession.h>
#import <MediaPlayer/MPNowPlayingInfoCenter.h>
#import <MediaPlayer/MediaPlayer.h>
//#import "Helper.h"
#import <ConnectSDK/ConnectSDK.h>
#import "ConnectError.h"
#import "MediaInfo+CustomData.h"
#import "NSBundle+MyBundle.h"
//#import "OLAuthenticationManager.h"
//#import "OrangeSTBService.h"


static ConnectCastManager *instance=nil;

@interface ConnectCastManager()<UIAlertViewDelegate>

@property(nonatomic, strong) LaunchSession* launchSession;
@property(nonatomic, strong) WebAppSession* webAppSession;
@property(nonatomic, strong) id<MediaControl> mediaControl;
@property(nonatomic, strong) ServiceSubscription* playStateSubscribption;

@property (nonatomic, retain) UIImage * btnImageBar;
@property (nonatomic, retain) UIImage * btnImageConnectedBar;

@property (nonatomic, retain) UIImage * btnImage;
@property (nonatomic, retain) UIImage * btnImageConnected;

@property (nonatomic, retain) UIImage * btnImageForPlayer;
@property (nonatomic, retain) UIImage * btnImageConnectedForPlayer;

@property (nonatomic, assign) BOOL deviceMuted;
@property (nonatomic, assign) BOOL connecting;

@property (nonatomic, assign) dispatch_queue_t queue;

@property (nonatomic, readwrite, retain) NSMutableArray *tracks;

/** The UIBarButtonItem denoting the cast device. */
@property(nonatomic, readwrite, retain) UIBarButtonItem* castBarButton;

/** The UIBarButtonItem denoting the cast device. */
@property(nonatomic, readwrite, retain) UIButton* castButtonForPlayers;

/** The UIBarButtonItem denoting the cast device. */
@property(nonatomic, retain) UIButton* castButton;

/** The UIBarButtonItem denoting the cast device. */
@property(nonatomic, retain) UILabel* castLabel;

/** The UIBarButtonItem denoting the cast device. */
@property(nonatomic, readwrite, retain) UILabel* castView;


/** The UIButton denoting the movie tracks. */
@property(nonatomic,readwrite, retain) UIButton* castTrackButton;


@end


@implementation ConnectCastManager

#pragma mark - Init Method

/** get current cast manager */
+ (ConnectCastManager *)getInstance{
    if(instance==nil){
        instance = [[ConnectCastManager alloc]init];
    }
    return instance;
}

- (id)init {
    self.connecting = NO;
    return [self initChromecastManagerWithFeatures];
}


/** Initialize the controller with features for various experiences. */
- (id)initChromecastManagerWithFeatures{
    self = [super init];
    if (self) {
        
        // Initialize device scanner
        self.discoveryManager = [DiscoveryManager sharedManager];
        
        //init array of movie tracks
        self.tracks = [NSMutableArray array];
        
        // Initialize UI controls for navigation bar and tool bar.
        [self initControls];
        
        self.queue = dispatch_queue_create("com.google.sample.Chromecast", NULL);
        
    }
    return self;
}


#pragma mark - Connexion Method

- (void)performDeviceScan:(BOOL)start {
    
    if (start) {
        NSLog(@"Start Scan");
//        _discoveryManager.pairingLevel = DeviceServicePairingLevelOn;
        _discoveryManager.delegate = self;
        [_discoveryManager startDiscovery];
        
    } else {
        NSLog(@"Stop Scan");
        [_discoveryManager stopDiscovery];
    }
}

- (void)connectToDevice:(ConnectableDevice *)device {
    NSLog(@"Device address: %@:%d", device.address, (unsigned int) device.serviceDescription.port);
    self.selectedDevice = device;
    
    _selectedDevice = device;
    _selectedDevice.delegate = self;
    [_selectedDevice connect];
    
    [self startAnimatingButtons];
    
}

- (BOOL) isConnecting;
{
    return self.connecting;
}

- (void) startAnimatingButtons
{
    self.connecting = true;
    // Start animating the cast connect images.
    self.castButton.tintColor = [UIColor whiteColor];
    self.castButton.imageView.animationImages =
    @[[NSBundle imageNamed:@"cast_on0"], [NSBundle imageNamed:@"cast_on1"],
      [NSBundle imageNamed:@"cast_on2"], [NSBundle imageNamed:@"cast_on1"] ];
    self.castButton.imageView.animationDuration = 2;
    [self.castButton.imageView startAnimating];
    self.castLabel.text = @"connexion en cours";
    
    
    // Start animating the cast connect images.
    self.castButtonForPlayers.tintColor = [UIColor whiteColor];
    self.castButtonForPlayers.imageView.animationImages =
    @[[NSBundle imageNamed:@"cast_on0"], [NSBundle imageNamed:@"cast_on1"],
      [NSBundle imageNamed:@"cast_on2"], [NSBundle imageNamed:@"cast_on1"] ];
    self.castButtonForPlayers.imageView.animationDuration = 2;
    [self.castButtonForPlayers.imageView startAnimating];
    
    
    
    UIButton *castButton = (UIButton *)self.castBarButton.customView;
    castButton.tintColor = [UIColor whiteColor];
    castButton.imageView.animationImages =
    @[[NSBundle imageNamed:@"cast_on0"], [NSBundle imageNamed:@"cast_on1"],
      [NSBundle imageNamed:@"cast_on2"], [NSBundle imageNamed:@"cast_on1"] ];
    castButton.imageView.animationDuration = 2;
    [castButton.imageView startAnimating];
}

- (void) stopAnimatingButtons
{
    self.connecting = false;
    [self.castButton.imageView stopAnimating];
    UIButton *castButton = (UIButton *)self.castBarButton.customView;
    [castButton.imageView stopAnimating];
    [self.castButtonForPlayers.imageView stopAnimating];
}

- (void)disconnectFromDevice {
    NSLog(@"Disconnecting device:%@", self.selectedDevice.friendlyName);
    
    // Remove previously stored deviceID
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:@"lastDeviceID"];
    [defaults synchronize];

    [_selectedDevice disconnect];
}


#pragma mark - Implementation Method

- (void)initControls{
    // Create cast bar button.
    
    self.btnImageBar = [NSBundle imageNamed:@"cast_off"];
    self.btnImageConnectedBar = [NSBundle imageNamed:@"cast_on"];
    UIImage *imageButtonBar = [self getButtonImageFromCurrentState];
    
    UIButton *castButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [castButton addTarget:self
                         action:@selector(chooseDevice:)
               forControlEvents:UIControlEventTouchDown];
    castButton.frame = CGRectMake(0, 0, self.btnImageConnectedBar.size.width, self.btnImageConnectedBar.size.height);
    [castButton setImage:imageButtonBar forState:UIControlStateNormal];
    
    self.castBarButton = [[UIBarButtonItem alloc] initWithCustomView:castButton];
    self.castBarButton.customView.hidden = YES;
    
    //create option menu castView view
    
    self.castView = [[UIView alloc]initWithFrame:CGRectMake(0,0,190, 40)];
    self.castView.backgroundColor = [UIColor clearColor];
    
    self.btnImage = [NSBundle imageNamed:@"cast_off"];
    self.btnImageConnected = [NSBundle imageNamed:@"cast_on"];
    
    self.btnImageForPlayer = [NSBundle imageNamed:@"cast_off_black"];
    self.btnImageConnectedForPlayer = [NSBundle imageNamed:@"cast_on_black"];
    
    
    UIImage *imageButton = [self getButtonImageFromCurrentState];
    self.castLabel = [[UILabel alloc]initWithFrame:CGRectMake(0,0,self.castView.frame.size.width,self.castView.frame.size.height)];
    self.castLabel.backgroundColor = [UIColor clearColor];
    self.castLabel.textAlignment = NSTextAlignmentRight;
    self.castLabel.text = @"Aucun dongle";
    self.castLabel.textColor = [UIColor whiteColor];
    //self.castLabel.font = [UIFont orangeLightFontWithSize:18];
    [self.castView addSubview:self.castLabel];
    
    
    self.castButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.castButton addTarget:self
                        action:@selector(chooseDevice:)
              forControlEvents:UIControlEventTouchDown];
    self.castButton.frame = CGRectMake(self.castView.frame.size.width-self.btnImageConnected.size.width, ceilf((self.castView.frame.size.height-self.btnImageConnected.size.height)/2), self.btnImageConnected.size.width, self.btnImageConnected.size.height);
    [self.castButton setImage:imageButton forState:UIControlStateNormal];
    self.castButton.hidden = YES;
    [self.castView addSubview:self.castButton];
    
    
    UIImage *imageButtonForPlayer = [self getButtonImageFromCurrentState];
    self.castButtonForPlayers = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.castButtonForPlayers addTarget:self
                                  action:@selector(chooseDevice:)
                        forControlEvents:UIControlEventTouchDown];
    
    self.castButtonForPlayers.frame = CGRectMake(self.castView.frame.size.width-self.btnImageConnected.size.width, ceilf((self.castView.frame.size.height-self.btnImageConnected.size.height)/2),
                                                 self.btnImageConnected.size.width, self.btnImageConnected.size.height);
    [self.castButtonForPlayers setImage:imageButtonForPlayer forState:UIControlStateNormal];
    self.castButtonForPlayers.hidden = YES;
    
    if(self.discoveryManager.compatibleDevices.count>0){
        self.castBarButton.customView.hidden = NO;
        self.castButton.hidden = NO;
        self.castButtonForPlayers.hidden = NO;
        self.castLabel.frame = CGRectMake(0,0,self.castView.frame.size.width-self.castButton.frame.size.width-6,self.castView.frame.size.height);
        self.castLabel.text = [NSString  stringWithFormat:@"%lu dongle",(unsigned long)self.discoveryManager.compatibleDevices.count];
    }
    
    self.castTrackButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.castTrackButton addTarget:self
                                   action:@selector(chooseTrack:)
                         forControlEvents:UIControlEventTouchDown];
    self.castTrackButton.frame = CGRectMake(0,0, 100,40);
    [self.castTrackButton setTitle:@"VF" forState:UIControlStateNormal];
    [self.castTrackButton setTitle:@"VOSTFR" forState:UIControlStateSelected];
    [self.castTrackButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    self.castTrackButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    self.castTrackButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.castTrackButton.hidden = YES;
    
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleResignActive:)
                                                 name: UIApplicationWillResignActiveNotification
                                               object: nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleBecomeActive:)
                                                 name: UIApplicationDidBecomeActiveNotification
                                               object: nil];
    
    
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    [[AVAudioSession sharedInstance] addObserver:self
                   forKeyPath:@"outputVolume"
                      options:0
                      context:nil];
    
}

- (void) handleResignActive: (id)object{

}

- (void) handleBecomeActive: (id)object{
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
}


-(void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    if ([keyPath isEqual:@"outputVolume"]) {
        NSLog(@"volume changed!");
        float volume = [[AVAudioSession sharedInstance] outputVolume];
        if(self.selectedDevice.connected){
            [self.selectedDevice.volumeControl setVolume:volume success:^(id responseObject)
             {
                 NSLog(@"Vol Change Success %f", volume);
             } failure:^(NSError *setVolumeError)
             {
                 NSLog(@"Vol Change Error %@", setVolumeError.description);
                 [self.selectedDevice.volumeControl getVolumeWithSuccess:^(float volume)
                  {
                      NSLog(@"Vol rolled back to actual %f", volume);
                  } failure:^(NSError *getVolumeError)
                  {
                      NSLog(@"Vol serious error: %@", getVolumeError.localizedDescription);
                  }];
             }];
        }
    }
}



- (UIImage *)getButtonImageFromCurrentState{
    UIImage *img = nil;
    if([self isConnected]){
        img = [NSBundle imageNamed:@"cast_on"];
    }else{
        img = [NSBundle imageNamed:@"cast_off"];
    }
    return img;
}


- (void) hideCastButtons
{
    self.castBarButton.customView.hidden = YES;
    self.castButtonForPlayers.hidden = YES;
    self.castButton.hidden = YES;
    self.castLabel.frame = CGRectMake(0,0,self.castView.frame.size.width,self.castView.frame.size.height);
    self.castLabel.text = @"Aucun dongle";
}

- (void)updateCastIconButtonStates
{
    // Hide the button if there are no devices found.
    UIButton *castButton = (UIButton *)self.castBarButton.customView;
    if (self.discoveryManager.compatibleDevices.count == 0) {
        [self hideCastButtons];
    } else {
        self.castLabel.text = [NSString  stringWithFormat:@"%lu dongle",(unsigned long)self.discoveryManager.compatibleDevices.count];
        self.castBarButton.customView.hidden = NO;
        self.castButtonForPlayers.hidden = NO;
        self.castButton.hidden = NO;
        self.castLabel.frame = CGRectMake(0,0,self.castView.frame.size.width-self.castButton.frame.size.width-6,self.castView.frame.size.height);
        if (self.selectedDevice && self.selectedDevice.connected) {
            [self stopAnimatingButtons];
            // Hilight with yellow tint color.
            self.castLabel.text =  self.selectedDevice.friendlyName;
            [castButton setImage:self.btnImageConnectedBar forState:UIControlStateNormal];
            [self.castButton setImage:self.btnImageConnected forState:UIControlStateNormal];
            [self.castButtonForPlayers setImage:self.btnImageConnectedForPlayer forState:UIControlStateNormal];
            
        } else {
            [self stopAnimatingButtons];
            // Remove the highlight.
            [castButton setImage:self.btnImageBar forState:UIControlStateNormal];
            [self.castButton setImage:self.btnImage forState:UIControlStateNormal];
            [self.castButtonForPlayers setImage:self.btnImageForPlayer forState:UIControlStateNormal];
        }
    }
}


- (void) updateTrackCastButtonState{
    if([self isConnected]){
        if(self.tracks.count>1){
            __block int nbTrackAudio=0;
            //for(id track in self.tracks){
                
                ServiceCommand *command = [ServiceCommand commandWithDelegate:self.webAppSession target:nil payload:nil];
                command.HTTPMethod = @"getSelectedTracks";
                command.callbackComplete = ^(NSDictionary* selectedTracks)
                {
                    NSLog(@"get selected tracks success %@", selectedTracks);
                    nbTrackAudio = [selectedTracks[@"audioTracksCount"] intValue];
                    NSString* audioLang = selectedTracks[@"audioLanguage"];
                    if(![audioLang isEqualToString:@"und"]){
                        if([audioLang isEqualToString:@"fre"]){
                            self.castTrackButton.selected = NO;
                        }else{
                            self.castTrackButton.selected = YES;
                        }
                    }
                    
                    if(nbTrackAudio>1){
                        self.castTrackButton.hidden = NO;
                    }else{
                        self.castTrackButton.hidden = YES;
                    }

                };
                command.callbackError = ^(NSError *error)
                {
                    NSLog(@"change tracks error: %@", error);
                };
                [command send];

        }else{
            self.castTrackButton.hidden = YES;
        }
    }else{
        self.castTrackButton.hidden = YES;
    }
    self.castTrackButton.enabled = YES;
}


- (void)showError:(NSError *)error {
    NSLog(@"Received error: %@", error.description);
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"orange_info", nil)
                                                    message:NSLocalizedString(@"cast_failed_connection_lost", nil)
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                          otherButtonTitles:nil];
    [alert show];
}


- (void)chooseDevice:(id)sender {
    
    if(self.discoveryManager.compatibleDevices.count>0){
        if (self.isConnected && self.selectedDevice && !self.deviceInfoControllerDisabled) {
            [[NSNotificationCenter defaultCenter]postNotificationName:NOTIFICATION_CAST_PRESENT_DEVICE_INFO_CONTROLLER object:nil];
        }else{
            [[NSNotificationCenter defaultCenter]postNotificationName:NOTIFICATION_CAST_PRESENT_DEVICE_SELECTION_CONTROLLER object:sender];
        }
    }else{
        [self updateCastIconButtonStates];
    }
    
}



- (void)chooseTrack:(id)sender {
    self.castTrackButton.enabled = NO;
    if([self isConnected]){
        [[NSNotificationCenter defaultCenter]postNotificationName:NOTIFICATION_CAST_PRESENT_TRACKS_CONTROLLER object:nil];
    }else{
        [self updateTrackCastButtonState];
    }
}


- (void)changeTrackWithData:(NSDictionary *)data{
    if(data){
        if(self.castTrackButton.hidden==NO){
            
            ServiceCommand *command = [ServiceCommand commandWithDelegate:self.webAppSession target:nil payload:data];
            command.HTTPMethod = @"changeTracks";
            command.callbackComplete = ^(NSArray* tracks)
            {
                NSLog(@"change tracks success %@", tracks);
                //self.tracks = [NSMutableArray arrayWithArray:tracks];
                [self updateTrackCastButtonState];
            };
            command.callbackError = ^(NSError *error)
            {
                NSLog(@"change tracks error: %@", error);
            };
            [command send];
        }
    }else{
        [self updateTrackCastButtonState];
    }
}

- (void)toogleTracksVF_VOSTF{
    if(self.castTrackButton.hidden==NO){
        // VF/VOSTF toggle
        ServiceCommand *command = [ServiceCommand commandWithDelegate:self.webAppSession target:nil payload:@{@"VOSTFR":@(self.castTrackButton.selected)}];
        command.HTTPMethod = @"toggleTracks";
        command.callbackComplete = ^(NSDictionary* tracksToSelect)
        {
            NSLog(@"toggle tracks success %@", tracksToSelect);
            [self changeTrackWithData:tracksToSelect];
        };
        command.callbackError = ^(NSError *error)
        {
            NSLog(@"change tracks error: %@", error);
        };
        [command send];
    }
}

- (void)loadMediaStringURL:(MediaInfo *)mediaInfo
                 startTime:(NSTimeInterval)startTime
                  autoPlay:(BOOL)autoPlay
                   success:(void(^)()) success
                   failure:(void(^)()) failure{
    
    if (!self.selectedDevice || !self.selectedDevice.connected) {
        dispatch_on_main(^{ failure(); });
        return;
    }

    self.castTrackButton.selected = NO;
    self.castTrackButton.hidden = YES;
    BOOL shouldLoop = NO;

    
    [self.selectedDevice.mediaPlayer playMediaWithMediaInfo:mediaInfo shouldLoop:shouldLoop atPosition:startTime
                                                    success:^(MediaLaunchObject *launchObject) {
                                                        NSLog(@"cast video success");
                                                        self.launchSession = launchObject.session;
                                                        self.mediaControl = launchObject.mediaControl;
                                                        
                                                        self.connecting = NO;
                                                        [self updateCastIconButtonStates];
                                                        self.mediaInformation = mediaInfo;
                                                        
                                                        if ([self.selectedDevice hasCapability:kMediaControlPlayStateSubscribe]){
                                                            
                                                            [_mediaControl subscribePlayStateWithSuccess:^(MediaControlPlayState playstate) {
                                                                NSLog(@"Media control playstate changed %d", playstate);
                                                                _playerState = playstate;
            
                                                                [self updateStatsFromDevice];
                                                                
                                                                [[NSNotificationCenter defaultCenter]postNotificationName:NOTIFICATION_CAST_MEDIA_STATUS_CHANGE object:nil];
                                                                
                                                            }  failure:^(NSError *error)
                                                             {
                                                                 NSLog(@"subscribe media playstate subscribe failure: %@", error.localizedDescription);
                                                             }];
                                                        }
                                                        
                                                        [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
                                                        
                                                        Class playingInfoCenter = NSClassFromString(@"MPNowPlayingInfoCenter");
                                                        
                                                        if (playingInfoCenter) {
                                                            
                                                            NSDictionary *songInfo = [NSDictionary dictionaryWithObjectsAndKeys:mediaInfo.title, MPMediaItemPropertyTitle,
                                                                                      mediaInfo.description, MPMediaItemPropertyAlbumTitle,
                                                                                      nil];
                                                            [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:songInfo];
                                                        }
                                                        
                                                        dispatch_on_main(^{
                                                            success();
                                                        });
                                                        
                                                    } failure:^(NSError *error) {
                                                        NSLog(@"display video failure: %@", error.localizedDescription);
                                                        
                                                        if(self.isConnecting && [error code] == 8) {// == GCKErrorCodeApplicationNotRunning
                                                            // Expected error when unable to reconnect to previous session after another
                                                            // application has been running
                                                            self.connecting = false;
                                                        } else {
                                                            [self showError:error];
                                                        }
                                                        
                                                        [self deviceDisconnected];
                                                        [self updateCastIconButtonStates];
                                                        
                                                        dispatch_on_main(^{ failure(); });
                                                        
                                                    }];
    
    
}

- (void)loadMediaStringURL:(NSString *)url
        thumbnailStringURL:(NSString *)thumbnailURL
                     title:(NSString *)title
                  subtitle:(NSString *)subtitle
                  mimeType:(NSString *)mimeType
                 startTime:(NSTimeInterval)startTime
                  autoPlay:(BOOL)autoPlay
                     infos:(NSDictionary *)object
                   success:(void(^)()) success
                   failure:(void(^)()) failure{
    
    
    NSURL *mediaURL = [NSURL URLWithString:url];
    NSURL *iconURL = [NSURL URLWithString:thumbnailURL];
    
    MediaInfo *mediaInfo = [[MediaInfo alloc] initWithURL:mediaURL mimeType:mimeType];
    mediaInfo.title = title;
    mediaInfo.description = subtitle;
    ImageInfo *imageInfo = [[ImageInfo alloc] initWithURL:iconURL type:ImageTypeThumb];
    [mediaInfo addImage:imageInfo];
    
    [self loadMediaStringURL:mediaInfo startTime:startTime autoPlay:autoPlay success:success failure:failure];
}





- (CastViewController *) createMediaViewController:(MediaInfo *)mediaInformation {
    CastViewController *controlView = nil;
    NSBundle *bundle = [NSBundle bundleWithURL:[[NSBundle bundleForClass:[self class]] URLForResource:@"ConnectSDK-CompanionLibrary-iOS" withExtension:@"bundle"]];
    
    if(UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPhone){
        controlView = [[[CastViewController alloc]initWithNibName:CAST_VIEWCONTROLLER_PHONE bundle:bundle] autorelease];
    }else{
        controlView = [[[CastViewController alloc]initWithNibName:CAST_VIEWCONTROLLER_PAD bundle:bundle] autorelease];
    }

    NSURL* imageUrl = nil;
    if(mediaInformation.images && mediaInformation.images.count>0){
        ImageInfo *img = [mediaInformation.images objectAtIndex:0];
        imageUrl = img.url;
    }
    [controlView configureWithImageUrl:imageUrl  andTitle:mediaInformation.title subtitle:mediaInformation.description];
    [self getCastTrack];
    
    return controlView;
}


- (CastViewController *) createMediaViewControllerWithTitle:(NSString *)title Subtitle:(NSString *)subtitle Image:(UIImage *)image{
    CastViewController *controlView = nil;
    NSBundle *bundle = [NSBundle bundleWithURL:[[NSBundle bundleForClass:[self class]] URLForResource:@"ConnectSDK-CompanionLibrary-iOS" withExtension:@"bundle"]];
    
    if(UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPhone){
        controlView = [[[CastViewController alloc]initWithNibName:CAST_VIEWCONTROLLER_PHONE bundle:bundle] autorelease];
    }else{
        controlView = [[[CastViewController alloc]initWithNibName:CAST_VIEWCONTROLLER_PAD bundle:bundle] autorelease];
    }
    [controlView configureWithImage:image  andTitle:title subtitle:subtitle];
    [self getCastTrack];
    
    return controlView;
}

- (CastViewController *) createMediaViewControllerWithTitle:(NSString *)title Subtitle:(NSString *)subtitle ImageUrl:(NSURL *)imageUrl{
    CastViewController *controlView = nil;
    NSBundle *bundle = [NSBundle bundleWithURL:[[NSBundle bundleForClass:[self class]] URLForResource:@"ConnectSDK-CompanionLibrary-iOS" withExtension:@"bundle"]];
    
    if(UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPhone){
        controlView = [[[CastViewController alloc]initWithNibName:CAST_VIEWCONTROLLER_PHONE bundle:bundle] autorelease];
    }else{
        controlView = [[[CastViewController alloc]initWithNibName:CAST_VIEWCONTROLLER_PAD bundle:bundle] autorelease];
    }
    [controlView configureWithImageUrl:imageUrl  andTitle:title subtitle:subtitle];
    [self getCastTrack];
    
    return controlView;
}



- (BOOL) hasMediaInformation
{
    return [self isConnected] && self.mediaControl!=nil && self.mediaInformation!=nil;
}

- (NSString*) getMediaInfoTitle
{
    NSString* title = nil;
    if([self isConnected])
    {
        title = self.mediaInformation.title;
    }
    return title;
}

- (NSString*) getMediaInfoSubTitle
{
    NSString* subtitle = nil;
    if([self isConnected])
    {
        subtitle = self.mediaInformation.description;
    }
    return subtitle;
}

- (NSArray*) getMediaInfoImages
{
    NSArray* images = nil;
    if([self isConnected])
    {
        images = self.mediaInformation.images;
    }
    return images;
}



- (void) getCastTrack{
    
    ServiceCommand *command = [ServiceCommand commandWithDelegate:self.webAppSession target:nil payload:nil];
    command.HTTPMethod = @"getTracks";
    command.callbackComplete = ^(NSArray* tracks)
    {
        NSLog(@"tracks success %@", tracks);
        self.tracks = [NSMutableArray arrayWithArray:tracks];
        [self updateTrackCastButtonState];
    };
    command.callbackError = ^(NSError *error)
    {
        NSLog(@"tracks error: %@", error);
    };
    [command send];
    
}




#pragma mark - check value Method

- (BOOL)isConnected {
    return (_selectedDevice && _selectedDevice.connected);
}

- (BOOL)isPlayingMedia {
    return [self isConnected] && self.mediaControl &&
    (self.playerState == MediaControlPlayStatePlaying || self.playerState == MediaControlPlayStateBuffering);
}

- (NSString *)getDeviceName {
    if (self.selectedDevice == nil)
        return @"";
    return self.selectedDevice.friendlyName;
}


#pragma mark - Event method

- (void)setPlaybackPercent:(float)newPercent {
    newPercent = MAX(MIN(1.0, newPercent), 0.0);
    
    if (_mediaDuration > 0 && self.isConnected) {
    [_mediaControl getDurationWithSuccess:^(NSTimeInterval duration)
     {
         _mediaDuration = duration;
         
         [_mediaControl getPositionWithSuccess:^(NSTimeInterval position){} failure:nil];
         
         NSTimeInterval newTime = newPercent * _mediaDuration;
         [self setPlaybackPosition:newTime];

     } failure:^(NSError *error)
     {
         NSLog(@"get duration failure: %@", error.localizedDescription);
     }];
    }
}

- (void)setPlaybackPosition:(float)position {
    
    if (_mediaControl!=nil && self.isConnected) {
        
        NSTimeInterval newTime = position;
        
        [_mediaControl seek:newTime
                    success:^(id responseObject){
             NSLog(@"seek success");
         }
                    failure:^(NSError *error){
             NSLog(@"seek failure: %@", error.localizedDescription);
         }];
    }
}

- (void)pauseCastMedia:(BOOL)shouldPause {
    if (self.isConnected && self.mediaControl) {
        if (shouldPause) {
            [self.mediaControl pauseWithSuccess:^(id responseObject){
                 NSLog(@"pause success");
             }
                                        failure:^(NSError *error){
                 NSLog(@"pause failure: %@", error.localizedDescription);
             }];
        } else {
            [self.mediaControl playWithSuccess:^(id responseObject){
                 NSLog(@"play success");
             }
                                       failure:^(NSError *error){
                 NSLog(@"play failure: %@", error.localizedDescription);
             }];
        }
        [self updateStatsFromDevice];
    }
    
}

- (void)stopCastMedia {
    if (self.isConnected && self.mediaControl) {
        NSLog(@"Telling cast media control channel to stop");
        
        [self.mediaControl stopWithSuccess:^(id responseObject){
            NSLog(@"stop success");
            self.mediaControl = nil;
            self.mediaInformation = nil;
            [[NSNotificationCenter defaultCenter]postNotificationName:NOTIFICATION_CAST_STOPPED object:nil];
        }
                                   failure:^(NSError *error){
            NSLog(@"stop failure: %@", error.localizedDescription);
        }];
        
        [self updateStatsFromDevice];
    }
}

- (void)changeVolumeIncrease:(BOOL)goingUp {
    float idealVolume = self.deviceVolume + (goingUp ? 0.1 : -0.1);
    idealVolume = MIN(1.0, MAX(0.0, idealVolume));
    
    [self.selectedDevice.volumeControl setVolume:idealVolume
                                         success:^(id responseObject){
                                             _deviceVolume = idealVolume;
                                             self.deviceMuted = _deviceVolume == 0;
                                             // Fire off a notification, so no matter what controller we are in, we can show the volume slider
                                             [[NSNotificationCenter defaultCenter] postNotificationName:@"Volume changed" object:self];
                                         }
                                         failure:^(NSError* error){
                                         }];
}

- (void)updateStatsFromDevice {
    
    if (self.isConnected && self.mediaControl) {
        [_mediaControl getPositionWithSuccess:^(NSTimeInterval position){
                                            _mediaPosition = position;
                                          }
                                          failure:^(NSError* error){
                                          }];
        
        [_mediaControl getDurationWithSuccess:^(NSTimeInterval duration){
                                            _mediaDuration = duration;
                                          }
                                          failure:^(NSError* error){
                                          }];
        
        [_mediaControl getPlayStateWithSuccess:^(MediaControlPlayState playState){
                                          _playerState = playState;
                                          }
                                          failure:^(NSError* error){
                                          }];
        
        // FIXME: Change the need to import the category MediaInfo+CustomData.
        [_mediaControl getMediaMetaDataWithSuccess:^(id responseObject){
             NSURL *url = [NSURL URLWithString:[responseObject objectForKey:@"contentId"]];
             NSString *mimetype = [responseObject objectForKey:@"mimetype"];
             NSString* title = [responseObject objectForKey:@"title"];
             if(title != nil){
                 self.mediaInformation = [[MediaInfo alloc] initWithURL:url mimeType:mimetype];
                 self.mediaInformation.title = [responseObject objectForKey:@"title"];
                 self.mediaInformation.description = [responseObject objectForKey:@"subtitle"];
                 NSURL *imageUrl = [NSURL URLWithString:[responseObject objectForKey:@"iconURL"]];
                 ImageInfo* imageInfo = [[ImageInfo alloc] initWithURL:imageUrl type:ImageTypeThumb];
                 [self.mediaInformation addImage:imageInfo];
                 
                 self.mediaInformation.customData = [responseObject objectForKey:@"customData"];
             }
             [[NSNotificationCenter defaultCenter]postNotificationName:NOTIFICATION_CAST_MEDIA_STATUS_CHANGE object:nil];
         }
                                           failure:^(NSError* error){
         }];

    }
}

- (void) stopApplication
{
    [self.selectedDevice.webAppLauncher closeWebApp:nil
                                            success:^(id response){
                                                NSLog(@"close success");
                                            }
                                            failure:^(NSError* error){
                                                NSLog(@"close failed :%@", error.description);
                                            }];
}

- (void)deviceDisconnected {
    self.mediaControl = nil;
    self.webAppSession = nil;
    self.selectedDevice.delegate = nil;
    self.selectedDevice = nil;
    
    [[NSNotificationCenter defaultCenter]postNotificationName:NOTIFICATION_CAST_DISCONNECT object:nil];
}

- (void)deviceSelectionCancelled
{
    [[NSNotificationCenter defaultCenter]postNotificationName:NOTIFICATION_CAST_PRESENT_DEVICE_SELECTION_CANCELLED object:nil];
}

- (void)reconnectIfPossible:(ConnectableDevice*) device
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString* lastDeviceID = [defaults objectForKey:@"lastDeviceID"];
    
    if(lastDeviceID != nil){
        
        if(device == nil){
            BOOL isDeviceOnNetwork = [self.discoveryManager.compatibleDevices objectForKey:device.address] != nil;
            NSLog(@"reconnectIfPossible isDeviceOnNetwork:%d lastDeviceID:%@", isDeviceOnNetwork, lastDeviceID);
            if(lastDeviceID != nil && [[device id] isEqualToString:lastDeviceID] && isDeviceOnNetwork){
                self.connecting = true;
                [self connectToDevice:device];
            }
        }
        else{
            NSLog(@"reconnectIfPossible lastDeviceID:%@", lastDeviceID);
            for(NSString* deviceIp in self.discoveryManager.compatibleDevices)
            {
                ConnectableDevice* device = [self.discoveryManager.compatibleDevices objectForKey:deviceIp];
                if([[device id] isEqualToString:lastDeviceID])
                {
                    self.connecting = true;
                    [self connectToDevice:device];
                }
            }
        }
    }
}

- (void)reconnectIfPossible
{
    [self reconnectIfPossible:nil];
}


#pragma mark - ConnectableDeviceDelegate

- (void) connectableDeviceReady:(ConnectableDevice *)device
{
    NSLog(@"connected to %@", device.friendlyName);
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString* lastDeviceID = [defaults objectForKey:@"lastDeviceID"];
    if((lastDeviceID != nil && ![[device id] isEqualToString:lastDeviceID]) || self.webAppSession==nil){
        
        // Store sessionID in case of restart
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        //[defaults setObject:webAppSession.launchSession.sessionId forKey:@"lastSessionID"];
        [defaults setObject:[self.selectedDevice id] forKey:@"lastDeviceID"];
        [defaults synchronize];
        NSLog(@"lastDeviceID = %@", [self.selectedDevice id]);
    
//        if([self.selectedDevice serviceWithName:@"OrangeSTB"]!=nil){
//            OrangeSTBService* service = (OrangeSTBService*) [self.selectedDevice serviceWithName:@"OrangeSTB"];
//            
//            [self updateCastIconButtonStates];
//            [[NSNotificationCenter defaultCenter]postNotificationName:NOTIFICATION_CAST_CONNECT object:nil];
//            
//            //TEST
//            //http://192.168.1.10:8080/remoteControl/cmd?operation=07&id=*****************FASTFURIOUSW0097104_S_2424VIDEO_1&type=0&request=1&code=0000
//            //NSString *commandPath = [NSString stringWithFormat:@"http://%@:%@/", service.serviceDescription.address, @(service.serviceDescription.port)];
//            NSString *contentId = @"*****************LEPOUVOIRXXW0084001_S_2424VIDEO_1";
//            
//            //NSMutableString * request = [NSMutableString stringWithFormat:@"http://%@:%@/remoteControl/cmd?operation=%@&id=%@&type=%i&request=%i",service.serviceDescription.address, @(service.serviceDescription.port), @07,contentId, 0, 1];
//            NSMutableString * request = [NSMutableString stringWithFormat:@"http://%@:%@/remoteControl/cmd?operation=%@&id=%@&type=%i&request=%i&code=%@",service.serviceDescription.address, @8080, @"07",contentId, 0, 1, @"0000"];
//            
//
//            if (SHOULD_DISPLAY_REQUEST_TRACK) {
//                NSLog(@"%@", request);
//            }
//
//            NSURL *statusCommandURL = [NSURL URLWithString:request];
//            
//            ServiceCommand *command = [[ServiceCommand alloc] initWithDelegate:service target:statusCommandURL payload:nil];
//            command.HTTPMethod = @"GET";
//            command.callbackComplete = ^(NSString *locationPath)
//            {
//                NSLog(@"success");
//            };
////            command.callbackError = failure;
//            [command send];
//
//            
//        }else{
        [self.selectedDevice.webAppLauncher launchWebAppWithSuccess:^(WebAppSession *webAppSession) {
                
                //self.launchSession = webAppSession;
                self.mediaControl = webAppSession.mediaControl;
                self.webAppSession = webAppSession;
                [self updateCastIconButtonStates];
                //[self updateStatsFromDevice];
            
                
                [[NSNotificationCenter defaultCenter]postNotificationName:NOTIFICATION_CAST_CONNECT object:nil];
                
                if ([self.selectedDevice hasCapability:kMediaControlMetadataSubscribe]){
                    
                    [_mediaControl subscribeMediaInfoWithSuccess:^(NSDictionary *responseObject) {
                        NSLog(@"Media control infos changed: %@", responseObject);
                        
                        //NSURL *url = [NSURL URLWithString:[responseObject objectForKey:@"contentId"]];
                        //NSString *mimetype = [responseObject objectForKey:@"mimetype"];
                        //self.mediaInformation = [[MediaInfo alloc] initWithURL:url mimeType:mimetype];
                        //self.mediaInformation.title = [responseObject objectForKey:@"title"];
                        //self.mediaInformation.description = [responseObject objectForKey:@"subtitle"];
                        //NSURL *imageUrl = [NSURL URLWithString:[responseObject objectForKey:@"iconURL"]];
                        //ImageInfo* imageInfo = [[ImageInfo alloc] initWithURL:imageUrl type:ImageTypeThumb];
                        //[self.mediaInformation addImage:imageInfo];
                        
                        
                        [self getCastTrack];
                        [self updateStatsFromDevice];
                        
                    }  failure:^(NSError *error)
                     {
                         NSLog(@"Media control infos update error");
                     }];
                }
                
            }andFailure:^(NSError *error) {
                NSLog(@"launch app failed: %@", error.localizedDescription);
            }];
    }else{
        [[NSNotificationCenter defaultCenter]postNotificationName:NOTIFICATION_CAST_CONNECT object:nil];
    }
    
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
}

- (void) connectableDevice:(ConnectableDevice *)device service:(DeviceService *)service pairingRequiredOfType:(int)pairingType withData:(id)pairingData
{
}

- (void) connectableDeviceDisconnected:(ConnectableDevice *)device withError:(NSError *)error
{
    NSLog(@"Received notification that device disconnected");
    
    if (error != nil) {
        [self showError:error];
    }
    
    [self deviceDisconnected];
    [self updateCastIconButtonStates];
    
     //dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
         [self reconnectIfPossible:device];
     //});
    
}

- (void) connectableDevice:(ConnectableDevice *)device connectionFailedWithError:(NSError *)error
{
    [self showError:error];
    
    [self deviceDisconnected];
    [self stopAnimatingButtons];
    [self updateCastIconButtonStates];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(buttonIndex == alertView.cancelButtonIndex)
    {
        [self reconnectIfPossible];
    }
}


#pragma mark - DiscoveryManagerDelegate
/*!
 * This method will be fired upon the first discovery of one of a ConnectableDevice's DeviceServices.
 *
 * @param manager DiscoveryManager that found device
 * @param device ConnectableDevice that was found
 */
- (void) discoveryManager:(DiscoveryManager *)manager didFindDevice:(ConnectableDevice *) device
{
//    for(DeviceService* service in device.services){
//        if(service!=nil){
//            device.id = service.serviceDescription.UUID;
//        }
//    }
    NSLog(@"device found!! %@ (id:%@)", device.friendlyName, device.id);
    
    [[NSNotificationCenter defaultCenter]postNotificationName:NOTIFICATION_CAST_DEVICE_DISCOVERED object:device];
    
    [self reconnectIfPossible:device];
    [self updateCastIconButtonStates];
    
}

/*!
 * This method is called when connections to all of a ConnectableDevice's DeviceServices are lost. This will usually happen when a device is powered off or loses internet connectivity.
 *
 * @param manager DiscoveryManager that lost device
 * @param device ConnectableDevice that was lost
 */
- (void) discoveryManager:(DiscoveryManager *)manager didLoseDevice:(ConnectableDevice *)device
{
    NSLog(@"device %@ (id:%@) went offline!!", device.friendlyName, device.id);
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString* lastDeviceID = [defaults objectForKey:@"lastDeviceID"];
    NSLog(@"lastDeviceID = %@", lastDeviceID);
    BOOL isLastDeviceLost = (self.discoveryManager.compatibleDevices.count==1 && [self.discoveryManager.compatibleDevices objectForKey:device.address] != nil);
    if((lastDeviceID != nil && [[device id] isEqualToString:lastDeviceID]) || self.discoveryManager.compatibleDevices.count==0){
        [self updateCastIconButtonStates];
    }
    if(isLastDeviceLost){
        [self hideCastButtons];
    }
}

/*!
 * This method is called when a ConnectableDevice gains or loses a DeviceService in discovery.
 *
 * @param manager DiscoveryManager that updated device
 * @param device ConnectableDevice that was updated
 */
- (void) discoveryManager:(DiscoveryManager *)manager didUpdateDevice:(ConnectableDevice *)device
{
    NSLog(@"");
}

/*!
 * In the event of an error in the discovery phase, this method will be called.
 *
 * @param manager DiscoveryManager that experienced the error
 * @param error NSError with a description of the failure
 */
- (void) discoveryManager:(DiscoveryManager *)manager didFailWithError:(NSError*)error
{
    NSLog(@"");
}


@end

