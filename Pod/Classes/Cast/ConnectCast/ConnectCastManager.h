#import <Foundation/Foundation.h>

#import "ConnectCastManagerDelegate.h"
#import "CastViewController.h"
//#import <ConnectSDK/ConnectSDK.h>
#import "ConnectSDK.h"

#define NOTIFICATION_CAST_CONNECT @"NOTIFICATION_CAST_CONNECT"
#define NOTIFICATION_CAST_DISCONNECT @"NOTIFICATION_CAST_DISCONNECT"
#define NOTIFICATION_CAST_MEDIA_STATUS_CHANGE @"NOTIFICATION_CAST_MEDIA_STATUS_CHANGE"
#define NOTIFICATION_CAST_PRESENT_CONTROLLER @"NOTIFICATION_CAST_PRESENT_CONTROLLER"
#define NOTIFICATION_CAST_DISMISS_CONTROLLER @"NOTIFICATION_CAST_DISMISS_CONTROLLER"
#define NOTIFICATION_CAST_STOPPED @"NOTIFICATION_CAST_STOPPED"
#define NOTIFICATION_CAST_DEVICE_DISCOVERED @"NOTIFICATION_CAST_DEVICE_DISCOVERED"
#define NOTIFICATION_CAST_PRESENT_TRACKS_CONTROLLER @"NOTIFICATION_CAST_PRESENT_TRACKS_CONTROLLER"
#define NOTIFICATION_CAST_PRESENT_DEVICE_INFO_CONTROLLER @"NOTIFICATION_CAST_PRESENT_DEVICE_INFO_CONTROLLER"
#define NOTIFICATION_CAST_PRESENT_DEVICE_SELECTION_CONTROLLER @"NOTIFICATION_CAST_PRESENT_DEVICE_SELECTION_CONTROLLER"
#define NOTIFICATION_CAST_PRESENT_DEVICE_SELECTION_CANCELLED @"NOTIFICATION_CAST_PRESENT_DEVICE_SELECTION_CANCELLED"

#define CAST_VIEWCONTROLLER_PHONE @"CastViewController_iPhone"
#define CAST_VIEWCONTROLLER_PAD @"CastViewController"
//#define CAST_VIEWCONTROLLER_PHONE @"VODECastViewController"
//#define CAST_VIEWCONTROLLER_PAD @"VODECastViewController"


@interface ConnectCastManager : NSObject<ConnectableDeviceDelegate, DiscoveryManagerDelegate>

#pragma mark - Properties

/** The device scanner used to detect devices on the network. */
@property(nonatomic, strong) DiscoveryManager* discoveryManager;

/** The media player state of the media on the device. */
@property(nonatomic, readonly) MediaControlPlayState playerState;

/** The media information of the loaded media on the device. */
@property(nonatomic, strong) MediaInfo* mediaInformation;

@property(nonatomic, strong) ConnectableDevice* selectedDevice;

/** Get the friendly name of the device. */
@property(readonly, getter=getDeviceName) NSString* deviceName;

/** Length of the media loaded on the device. */
@property(nonatomic, readonly) NSTimeInterval mediaDuration;

/** Current playback position of the media loaded on the device. */
@property(nonatomic, readonly) NSTimeInterval mediaPosition;

@property (nonatomic, readonly) NSMutableArray *tracks;

/** The UIBarButtonItem denoting the cast device. */
@property(nonatomic, readonly) UIBarButtonItem* castBarButton;

/** The UIBarButtonItem denoting the cast device. */
@property(nonatomic, readonly) UIButton* castButtonForPlayers;

/** The UIBarButtonItem denoting the cast device. */
@property(nonatomic, readonly) UIView* castView;

/** The UIButton denoting the movie tracks. */
@property(nonatomic,readonly) UIButton* castTrackButton;

/** The volume the device is currently at **/
@property(nonatomic) float deviceVolume;

@property (nonatomic, assign) BOOL deviceInfoControllerDisabled;

#pragma mark - Init Method

/** get current cast manager */
+ (ConnectCastManager *)getInstance;

/** Initialize the controller with features for various experiences. */
- (id)initChromecastManagerWithFeatures;


#pragma mark - check value Method

/** Returns true if connected to a cast device. */
- (BOOL)isConnected;

/** Returns true if media is loaded on the device. */
- (BOOL)isPlayingMedia;

#pragma mark - Connexion Method

/** Perform a device scan to discover devices on the network. */
- (void)performDeviceScan:(BOOL)start;

/** Connect to a specific cast device. */
- (void)connectToDevice:(ConnectableDevice*)device;

- (void)deviceSelectionCancelled;

/** Disconnect from a cast device. */
- (void)disconnectFromDevice;

#pragma mark - Event method

/** Pause or play the currently loaded media on the cast device. */
- (void)pauseCastMedia:(BOOL)shouldPause;

/** Request an update of media playback stats from the cast device. */
- (void)updateStatsFromDevice;

/** Sets the position of the playback on the cast device. */
- (void)setPlaybackPercent:(float)newPercent;
- (void)setPlaybackPosition:(float)position;

/** Stops the media playing on the cast device. */
- (void)stopCastMedia;

/** Increase or decrease the volume on the cast device. */
- (void)changeVolumeIncrease:(BOOL)goingUp;

- (void)updateTrackCastButtonState;

- (void)changeTrackWithData:(NSDictionary *)data;

/** Load a media on the device with supplied media metadata. */
- (void)loadMediaStringURL:(NSString *)url
     thumbnailStringURL:(NSString *)thumbnailURL
            title:(NSString*)title
         subtitle:(NSString*)subtitle
         mimeType:(NSString*)mimeType
        startTime:(NSTimeInterval)startTime
         autoPlay:(BOOL)autoPlay
            infos:(NSDictionary *)object
          success:(void(^)()) success
          failure:(void(^)()) failure;

- (void)loadMediaStringURL:(MediaInfo *)mediaInfo
                 startTime:(NSTimeInterval)startTime
                  autoPlay:(BOOL)autoPlay
                   success:(void(^)()) success
                   failure:(void(^)()) failure;


- (CastViewController *)createMediaViewControllerWithTitle:(NSString *)title Subtitle:(NSString *)subtitle Image:(UIImage *)image;
- (CastViewController *)createMediaViewControllerWithTitle:(NSString *)title Subtitle:(NSString *)subtitle ImageUrl:(NSURL *)imageUrl;
- (CastViewController *)createMediaViewController:(MediaInfo *)mediaInformation;

- (void)toogleTracksVF_VOSTF;

- (NSString*) getMediaInfoTitle;
- (NSString*) getMediaInfoSubTitle;
- (NSArray*) getMediaInfoImages;
- (BOOL) hasMediaInformation;
- (void) startAnimatingButtons;
- (BOOL) isConnecting;
- (void) stopAnimatingButtons;
- (void) stopApplication;


@end
