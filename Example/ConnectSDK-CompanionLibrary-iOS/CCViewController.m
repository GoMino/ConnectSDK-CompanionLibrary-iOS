//
//  CCViewController.m
//  ConnectSDK-CompanionLibrary-iOS
//
//  Created by Amine Bezzarga on 12/09/2015.
//  Copyright (c) 2015 Amine Bezzarga. All rights reserved.
//

#import "CCViewController.h"
#import "ConnectCastManager.h"
#import "CastDeviceSelectionView.h"
#import "CastAlertView.h"
#import "CastBannerView.h"
#import "MediaInfo+CustomData.h"
#import "UINavigationController+LockableRotation.h"
#import "NSBundle+MyBundle.h"

#define SHOW_BANNER 1

@interface CCViewController ()
<CastDeviceSelectionDelegate, CastAlertViewDelegate, CastBannerViewDelegate, DevicePickerDelegate>

@property (nonatomic, retain) CastDeviceSelectionView *deviceSelectionView;
@property (nonatomic, retain) CastAlertView *alertDisconnect;
@property (nonatomic, retain) CastBannerView *banner;
@property (nonatomic, retain) CastViewController *detailsChromecastController;
@property (nonatomic, retain) ConnectableDevice* selectedDevice;
@property (nonatomic, retain) DevicePicker* devicePicker;

@end

@implementation CCViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(presentControllerChromeCast:) name:NOTIFICATION_CAST_PRESENT_CONTROLLER object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dismissControllerChromeCast) name:NOTIFICATION_CAST_DISMISS_CONTROLLER object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopControllerChromeCast) name:NOTIFICATION_CAST_STOPPED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(castManagerDidConnectToDevice:) name:NOTIFICATION_CAST_CONNECT object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(castManagerDidDisconnect:) name:NOTIFICATION_CAST_DISCONNECT object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(castManagerDidReceiveMediaStateChange:) name:NOTIFICATION_CAST_MEDIA_STATUS_CHANGE object:nil];
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(castManagerDidDiscoverDeviceOnNetwork:) name:NOTIFICATION_CAST_DEVICE_DISCOVERED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(castManagerShouldDisplayModalDeviceController:) name:NOTIFICATION_CAST_PRESENT_DEVICE_INFO_CONTROLLER object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(castManagerShouldDisplayModalDeviceSelectionController:) name:NOTIFICATION_CAST_PRESENT_DEVICE_SELECTION_CONTROLLER object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(castManagerShouldPresentTracksController:) name:NOTIFICATION_CAST_PRESENT_TRACKS_CONTROLLER object:nil];
    
    self.navigationItem.rightBarButtonItem = [ConnectCastManager getInstance].castBarButton;
    self.navigationController.toolbarHidden = YES;
#if SHOW_BANNER
    self.banner = [CastBannerView getView];
    self.banner.delegate = self;
#endif
}

- (void) viewDidUnload
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_CAST_PRESENT_CONTROLLER object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_CAST_DISMISS_CONTROLLER object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_CAST_STOPPED object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_CAST_CONNECT object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_CAST_DISCONNECT object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_CAST_MEDIA_STATUS_CHANGE object:nil];
    //[[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_CAST_DEVICE_DISCOVERED object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_CAST_PRESENT_DEVICE_INFO_CONTROLLER object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_CAST_PRESENT_DEVICE_SELECTION_CONTROLLER object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_CAST_PRESENT_TRACKS_CONTROLLER object:nil];
}

- (void) viewDidAppear:(BOOL)animated
{
    if(self.banner!=nil && ![self.banner isDescendantOfView:self.navigationController.toolbar]){
        self.banner.frame = CGRectMake(0,0,self.view.frame.size.width,self.navigationController.toolbar.frame.size.height);
        [self.navigationController.toolbar addSubview:self.banner];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)shouldAutorotate
{
    return NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)loadMedia:(id)sender {
    
    if([ConnectCastManager getInstance].isConnected){
        NSLog(@"try to cast a media");
        
        NSString *title = @"title";
        NSString *sub = @"description";
        NSString* stringURLlimg = @"http://www.ocs.fr/data_plateforme/program/24638/tv_detail_afterearthxw0079615_csn_b409c.jpg";
        NSString* streaming = @"http://amssamples.streaming.mediaservices.windows.net/f1ee994f-fcb8-455f-a15d-07f6f2081a60/SintelMultiAudio.ism/manifest";
        //NSString* streaming = @"http://playready.directtaps.net/smoothstreaming/SSWSS720H264/SuperSpeedway_720.ism/Manifest";
        //NSString* streaming = @"http://labgency.cdn.mediactive-network.net/cdn/ofr.ocs/v4/m/1992XXX0107W0098264CJITS449770-D933/C45BC635-1AF5-4A02-8007-B5CA5340B065/1992XXX0107W0098264CJITS449770-D933.C45BC635-1AF5-4A02-8007-B5CA5340B065.X.mpd";
        NSDictionary* customData = @{
                                     //@"hss_license_url":@"http://ocu03.labgency.ws/catalog/license3?param=vod-sd"
                                     };
        NSLog(@"CAST URL:%@ customData:%@", streaming, customData);
        
        NSURL *mediaURL = [NSURL URLWithString:streaming];
        NSURL *iconURL = [NSURL URLWithString:stringURLlimg];
        
        MediaInfo *mediaInfo = [[MediaInfo alloc] initWithURL:mediaURL mimeType:@"video/any"];
        mediaInfo.title = title;
        mediaInfo.description = sub;
        ImageInfo *imageInfo = [[ImageInfo alloc] initWithURL:iconURL type:ImageTypeThumb];
        [mediaInfo addImage:imageInfo];
        [mediaInfo addImage:imageInfo];
        
        mediaInfo.customData = customData;
        
        [[ConnectCastManager getInstance] loadMediaStringURL:mediaInfo startTime:0 autoPlay:YES
                                                     success:^{
                                                         NSLog(@"cast success");
                                                         MediaInfo* mediaInformation = [[ConnectCastManager getInstance] mediaInformation];
                                                         if(mediaInformation){
                                                             [[NSNotificationCenter defaultCenter]postNotificationName:NOTIFICATION_CAST_PRESENT_CONTROLLER object:mediaInformation];
                                                         }
                                                     } failure:^{
                                                         NSLog(@"cast failure");
                                                     }];

    }else{
        UIAlertView *alertview = [[UIAlertView alloc] initWithTitle:@"Information" message:@"Connect to a device first" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alertview show];
    }
}


- (void) presentControllerChromeCast:(NSNotification *)notification{
    MediaInfo *info = nil;
    if(notification.object){
        
        if([self presentedViewController]!=nil && [self.presentedViewController isKindOfClass:[CastViewController class]]){
            return;
        }
        
        info = (MediaInfo *)notification.object;
        if(info){
            self.detailsChromecastController = [[ConnectCastManager getInstance]createMediaViewController:info];
        }
        
        //self.detailsChromecastController.delegate = self;
        if([self presentedViewController]!=nil && ![self.presentedViewController isKindOfClass:[CastViewController class]]){
            
                NSLog(@"will dismiss");
                [self dismissViewControllerAnimated:YES completion:^(void){
                    NSLog(@"will present");
                    [self presentViewController:self.detailsChromecastController animated:YES completion:^{
                        NSLog(@"should be presented");
                        if(SHOW_BANNER)
                            self.banner.userInteractionEnabled = NO;
                        
                    }];
                    
                }];
            
        }else{
            [self presentViewController:self.detailsChromecastController animated:YES completion:^{
                if(SHOW_BANNER)
                    self.banner.userInteractionEnabled = NO;
                
            }];
        }
    }
}

- (void) dismissControllerChromeCast{
    if(self.detailsChromecastController){
        [self.detailsChromecastController dismissViewControllerAnimated:YES completion:^{
            if(SHOW_BANNER)
                self.banner.userInteractionEnabled = YES;
        }];
    }
}

- (void) stopControllerChromeCast{
    if(SHOW_BANNER){
        self.navigationController.toolbarHidden = YES;
    }
}


- (void)castManagerDidConnectToDevice:(NSNotification *)notification{
    [[ConnectCastManager getInstance] stopAnimatingButtons];
    
    if(SHOW_BANNER){
        if([[ConnectCastManager getInstance] hasMediaInformation]){
            self.navigationController.toolbarHidden = NO;
        }else{
            self.navigationController.toolbarHidden = YES;
        }
    }
}

- (void)castManagerDidDisconnect:(NSNotification *)notification{
    if(SHOW_BANNER){
        self.navigationController.toolbarHidden = YES;
    }
    self.selectedDevice = nil;
    
    //    NSDictionary* customData =  [[ConnectCastManager getInstance] mediaInformation].customData;
    //    NSLog(@"custom data:%@", customData);
}

- (void)castManagerDidReceiveMediaStateChange:(NSNotification *)notification{
    
    NSString *mediatitle = nil;
    NSString *mediaSubtitle = nil;
    NSURL* imageUrl = nil;
    
    if([[ConnectCastManager getInstance] hasMediaInformation]){
        
        if(SHOW_BANNER){
            self.navigationController.toolbarHidden = NO;
        }
        
        if([[ConnectCastManager getInstance] getMediaInfoImages]!=nil){
            if([[ConnectCastManager getInstance] getMediaInfoImages].count>0){
                ImageInfo *img =[[[ConnectCastManager getInstance] getMediaInfoImages] objectAtIndex:0];
                imageUrl = img.url;
            }
            mediatitle = [[ConnectCastManager getInstance] getMediaInfoTitle];
            mediaSubtitle = [[ConnectCastManager getInstance] getMediaInfoSubTitle];
        }
        
    }
    NSString *deviceName = [[ConnectCastManager getInstance] getDeviceName];
    
    if(self.alertDisconnect!=nil){
        [self.alertDisconnect updateContentDeviceName:deviceName title:mediatitle subtitle:mediaSubtitle imageUrl:imageUrl withPlayingState:[[ConnectCastManager getInstance] isPlayingMedia]];
    }
    
    if(SHOW_BANNER && self.banner){
        int state = [[ConnectCastManager getInstance] playerState];
        if(state==MediaControlPlayStateIdle || ![[ConnectCastManager getInstance] hasMediaInformation]){
            self.navigationController.toolbarHidden = YES;
        }else{
            [self.banner updateContentTitle:mediatitle subtitle:mediaSubtitle imageUrl:imageUrl withPlayingState:[[ConnectCastManager getInstance] isPlayingMedia]];
            self.navigationController.toolbarHidden = NO;
        }
        
        //[self.navigationController.toolbar addSubview:self.banner];
    }
    
    //[[ConnectCastManager getInstance] updateStatsFromDevice];
    int state = [[ConnectCastManager getInstance] playerState];
    switch (state) {
        case MediaControlPlayStateUnknown:
            break;
        case MediaControlPlayStateIdle:
            break;
        case MediaControlPlayStateBuffering:
            break;
        case MediaControlPlayStatePlaying:
            break;
        case MediaControlPlayStatePaused:
            break;
        case MediaControlPlayStateFinished:
            [[ConnectCastManager getInstance] stopCastMedia];
            break;
        default:
            break;
    }
}


- (void)castManagerShouldDisplayModalDeviceSelectionController:(NSNotification *)notification{
    
    if([[[ConnectCastManager getInstance] discoveryManager]compatibleDevices] && [[[[ConnectCastManager getInstance] discoveryManager]compatibleDevices]count]>0){
        
        self.deviceSelectionView = [[[NSBundle MYBundle] loadNibNamed:@"CastDeviceSelectionView" owner:nil options:nil] lastObject];
        
        self.deviceSelectionView.frame = CGRectMake(0,self.view.frame.origin.y,
                                                    self.view.frame.size.width,
                                                    self.view.frame.size.height);
        
        for(ConnectableDevice* device in [[[[ConnectCastManager getInstance] discoveryManager]compatibleDevices]allValues]){
            CastButton *button = [[CastButton alloc]initWithFrame:CGRectMake(0,0,260, 48)];
            button.mainTitle = device.friendlyName;
            button.subTitle = [device connectedServiceNames];
            [self.deviceSelectionView addButton:button];
        }
        
        self.deviceSelectionView.delegate = self;
        if(self.detailsChromecastController){
            [self.detailsChromecastController.view addSubview:self.deviceSelectionView];
        }else{
            [self.view addSubview:self.deviceSelectionView];
        }
        
        [self.deviceSelectionView compile];
        
        
        //****** display a generic view to pick a device ******
//        if(![[ConnectCastManager getInstance] isConnecting]){
//            if (_devicePicker == nil)
//            {
//                _devicePicker = [[DiscoveryManager sharedManager] devicePicker];
//                _devicePicker.delegate = self;
//            }
//            
//            _devicePicker.currentDevice = [ConnectCastManager getInstance].selectedDevice;
//            //[_devicePicker showPicker:nil];
//            
//            [_devicePicker showActionSheet:notification.object];
//        };
        
    }
}

- (void)castManagerShouldDisplayModalDeviceController:(NSNotification *)notification{
    
    if(self.alertDisconnect==nil){
        self.alertDisconnect = [CastAlertView getView];
        
        NSString *mediatitle = nil;
        NSString *mediaSubtitle = nil;
        NSURL* imageUrl = nil;
        if([[ConnectCastManager getInstance] hasMediaInformation]){
            if([[ConnectCastManager getInstance] getMediaInfoImages] != nil){
                mediatitle = [[ConnectCastManager getInstance] getMediaInfoTitle];
                mediaSubtitle = [[ConnectCastManager getInstance] getMediaInfoSubTitle];
                
                if([[ConnectCastManager getInstance] getMediaInfoImages].count>0){
                    ImageInfo *img =[[[ConnectCastManager getInstance] getMediaInfoImages] objectAtIndex:0];
                    imageUrl = img.url;
                }
            }
        }
        
        NSString *deviceName = [[ConnectCastManager getInstance] getDeviceName];
        [self.alertDisconnect updateContentDeviceName:deviceName title:mediatitle subtitle:mediaSubtitle imageUrl:imageUrl withPlayingState:[[ConnectCastManager getInstance] isPlayingMedia]];
        
        self.alertDisconnect.delegate = self;
        
        // We need to add it to the window, which we can get from the delegate
        id appDelegate = [[UIApplication sharedApplication] delegate];
        UIWindow *window = [appDelegate window];
        
        // Make sure the alert covers the whole window
        self.alertDisconnect.frame = window.frame;
        self.alertDisconnect.center = window.center;
        
        //        if((UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])) && !SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")){
        //            //self.alertDisconnect.frame = CGRectMake(0,0,self.alertDisconnect.bounds.size.height,self.alertDisconnect.bounds.size.width);
        //            self.alertDisconnect.center =  CGPointMake(window.center.y, window.center.x);//because in landscape x becomes y
        //        }else{
        //            //self.alertDisconnect.frame = window.frame;
        //            self.alertDisconnect.center = window.center;
        //        }
        
        [window addSubview:self.alertDisconnect];
    }
}


- (void)castManagerShouldPresentPlaybackController:(NSNotification *)notification{
    NSLog(@"castManagerShouldPresentTracksController");
}


- (void)castManagerShouldPresentTracksController:(NSNotification *)notification{
    NSLog(@"castManagerShouldPresentTracksController");
}


#pragma mark - DevicePickerDelegate methods

- (void)devicePicker:(DevicePicker *)picker didSelectDevice:(ConnectableDevice *)device
{
    if(![[ConnectCastManager getInstance] isConnecting]){;
        self.selectedDevice = device;
        if(self.selectedDevice){
            [[ConnectCastManager getInstance] startAnimatingButtons];
            [[ConnectCastManager getInstance] connectToDevice:self.selectedDevice];
        }
    }
}

- (void) devicePicker:(DevicePicker *)picker didCancelWithError:(NSError *)error
{
    [[ConnectCastManager getInstance] deviceSelectionCancelled];
}

#pragma mark - CastDeviceSelectionDelegate

- (void) castDeviceSelectionViewDidCancel{
    [self.deviceSelectionView removeFromSuperview];
}

- (void) castDeviceSelectionViewDidSelectIndex:(int)index{
    [self.deviceSelectionView removeFromSuperview];
    if(![[ConnectCastManager getInstance] isConnecting]){;
        NSArray * devices = [[[[ConnectCastManager getInstance] discoveryManager]compatibleDevices] allValues];
        if(devices && devices.count>0 && devices.count>index){
            self.selectedDevice = [devices objectAtIndex:index];
            if(self.selectedDevice){
                [[ConnectCastManager getInstance]connectToDevice:self.selectedDevice];
            }
        }
    }
}

#pragma mark - CastAlertViewDelegate

- (void) castAlertViewClickToCancel{
    [self.alertDisconnect removeFromSuperview];
    self.alertDisconnect = nil;
}

- (void) castAlertViewClickToDisconnect{
    NSDictionary* customData =  [[ConnectCastManager getInstance] mediaInformation].customData;
    NSLog(@"custom data:%@", customData);
    
    //[[ConnectCastManager getInstance] stopApplication];
    [[ConnectCastManager getInstance] disconnectFromDevice];
    [self.alertDisconnect removeFromSuperview];
    self.alertDisconnect = nil;
    self.selectedDevice = nil;
}

- (void) castAlertViewClickTogglePlayPause{
    if(![[ConnectCastManager getInstance] isPlayingMedia]){
        [[ConnectCastManager getInstance] pauseCastMedia:NO];
    }else{
        [[ConnectCastManager getInstance] pauseCastMedia:YES];
    }
}

- (void) castAlertViewClickGoToFullscreen
{
    if(SHOW_BANNER)
        self.banner.userInteractionEnabled = NO;
    
    id mediaInformation = [[ConnectCastManager getInstance] mediaInformation];
    if(mediaInformation!=nil){
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_CAST_PRESENT_CONTROLLER object:mediaInformation];
    }
    [self.alertDisconnect removeFromSuperview];
    self.alertDisconnect = nil;
}


#pragma mark - CastBannerViewDelegate

-(void) castBannerViewTapOnPlay{
    if(![[ConnectCastManager getInstance] isPlayingMedia]){
        [[ConnectCastManager getInstance] pauseCastMedia:NO];
    }else{
        [[ConnectCastManager getInstance] pauseCastMedia:YES];
    }
}

- (void) castBannerViewTapOpenDetail{
    self.banner.userInteractionEnabled = NO;
    id mediaInformation = [[ConnectCastManager getInstance] mediaInformation];
    if(mediaInformation!=nil){
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_CAST_PRESENT_CONTROLLER object:mediaInformation];
    }
}

@end
