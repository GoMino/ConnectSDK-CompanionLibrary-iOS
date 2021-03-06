//
//  CastService.m
//  Connect SDK
//
//  Created by Jeremy White on 2/7/14.
//  Copyright (c) 2014 LG Electronics.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import <GoogleCast/GoogleCast.h>
#import "CastService.h"
#import "ConnectError.h"
#import "CastWebAppSession.h"
#import "MediaInfo+CustomData.h"

#define kCastServiceMuteSubscriptionName @"mute"
#define kCastServiceVolumeSubscriptionName @"volume"

@interface CastService () <ServiceCommandDelegate>

@end

@implementation CastService
{
    int UID;

    NSString *_currentAppId;
    NSString *_launchingAppId;

    NSMutableDictionary *_launchSuccessBlocks;
    NSMutableDictionary *_launchFailureBlocks;

    NSMutableDictionary *_sessions; // TODO: are we using this? get rid of it if not
    NSMutableArray *_subscriptions;

    float _currentVolumeLevel;
    BOOL _currentMuteStatus;
}

- (void) commonSetup
{
    //self.receiverAppId = kGCKMediaDefaultReceiverApplicationID;
    self.receiverAppId = @"5DD1C5A5";
    _launchSuccessBlocks = [NSMutableDictionary new];
    _launchFailureBlocks = [NSMutableDictionary new];

    _sessions = [NSMutableDictionary new];
    _subscriptions = [NSMutableArray new];

    UID = 0;
}

- (instancetype) init
{
    self = [super init];

    if (self)
        [self commonSetup];

    return self;
}

- (instancetype)initWithServiceConfig:(ServiceConfig *)serviceConfig
{
    self = [super initWithServiceConfig:serviceConfig];

    if (self)
        [self commonSetup];

    return self;
}

+ (NSDictionary *) discoveryParameters
{
    return @{
             @"serviceId":kConnectSDKCastServiceId
             };
}

- (BOOL)isConnectable
{
    return YES;
}

- (void) updateCapabilities
{
    NSArray *capabilities = [NSArray new];

    capabilities = [capabilities arrayByAddingObjectsFromArray:kMediaPlayerCapabilities];
    capabilities = [capabilities arrayByAddingObjectsFromArray:kVolumeControlCapabilities];
    capabilities = [capabilities arrayByAddingObjectsFromArray:@[
            kMediaControlPlay,
            kMediaControlPause,
            kMediaControlStop,
            kMediaControlDuration,
            kMediaControlSeek,
            kMediaControlPosition,
            kMediaControlPlayState,
            kMediaControlPlayStateSubscribe,
            kMediaControlMetadata,
            kMediaControlMetadataSubscribe,

            kWebAppLauncherLaunch,
            kWebAppLauncherMessageSend,
            kWebAppLauncherMessageReceive,
            kWebAppLauncherMessageSendJSON,
            kWebAppLauncherMessageReceiveJSON,
            kWebAppLauncherConnect,
            kWebAppLauncherDisconnect,
            kWebAppLauncherJoin,
            kWebAppLauncherClose
    ]];

    [self setCapabilities:capabilities];
}

- (void) sendNotSupportedFailure:(FailureBlock)failure
{
    if (failure)
        failure([ConnectError generateErrorWithCode:ConnectStatusCodeNotSupported andDetails:nil]);
}

#pragma mark - Connection

- (void)connect
{
    if (self.connected)
        return;

    if (!_castDevice)
    {
        UInt32 devicePort = (UInt32) self.serviceDescription.port;
        _castDevice = [[GCKDevice alloc] initWithIPAddress:self.serviceDescription.address servicePort:devicePort];
    }
    
    if (!_castDeviceManager)
    {
        NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
        NSString *clientPackageName = [info objectForKey:@"CFBundleIdentifier"];
        
        _castDeviceManager = [[GCKDeviceManager alloc] initWithDevice:_castDevice clientPackageName:clientPackageName];
        _castDeviceManager.delegate = self;
    }
    
    [_castDeviceManager connect];
}

- (void)disconnect
{
    if (!self.connected)
        return;

    self.connected = NO;

    [_castDeviceManager leaveApplication];
    [_castDeviceManager disconnect];

    if (self.delegate && [self.delegate respondsToSelector:@selector(deviceService:disconnectedWithError:)])
        dispatch_on_main(^{ [self.delegate deviceService:self disconnectedWithError:nil]; });
}

#pragma mark - Subscriptions

- (int)sendSubscription:(ServiceSubscription *)subscription type:(ServiceSubscriptionType)type payload:(id)payload toURL:(NSURL *)URL withId:(int)callId
{
    if (type == ServiceSubscriptionTypeUnsubscribe)
        [_subscriptions removeObject:subscription];
    else if (type == ServiceSubscriptionTypeSubscribe)
        [_subscriptions addObject:subscription];

    return callId;
}

- (int) getNextId
{
    UID = UID + 1;
    return UID;
}

#pragma mark - GCKDeviceManagerDelegate

- (void)deviceManagerDidConnect:(GCKDeviceManager *)deviceManager
{
    DLog(@"connected");

    self.connected = YES;

    _castMediaControlChannel = [[GCKMediaControlChannel alloc] init];
    [_castDeviceManager addChannel:_castMediaControlChannel];

    dispatch_on_main(^{ [self.delegate deviceServiceConnectionSuccess:self]; });
}

- (void)deviceManager:(GCKDeviceManager *)deviceManager didConnectToCastApplication:(GCKApplicationMetadata *)applicationMetadata sessionID:(NSString *)sessionID launchedApplication:(BOOL)launchedApplication
{
    DLog(@"%@ (%@)", applicationMetadata.applicationName, applicationMetadata.applicationID);

    _currentAppId = applicationMetadata.applicationID;

    WebAppLaunchSuccessBlock success = [_launchSuccessBlocks objectForKey:applicationMetadata.applicationID];

    LaunchSession *launchSession = [LaunchSession launchSessionForAppId:applicationMetadata.applicationID];
    launchSession.name = applicationMetadata.applicationName;
    launchSession.sessionId = sessionID;
    launchSession.sessionType = LaunchSessionTypeWebApp;
    launchSession.service = self;

    CastWebAppSession *webAppSession = [[CastWebAppSession alloc] initWithLaunchSession:launchSession service:self];
    webAppSession.metadata = applicationMetadata;
    
    _castMediaControlChannel.delegate = webAppSession;
    
    NSInteger requestId = [_castMediaControlChannel requestStatus];
    if(requestId == kGCKInvalidRequestID){
        DLog("Couldn't send request status")
    }

    [_sessions setObject:webAppSession forKey:applicationMetadata.applicationID];

    if (success)
        dispatch_on_main(^{ success(webAppSession); });

    [_launchSuccessBlocks removeObjectForKey:applicationMetadata.applicationID];
    [_launchFailureBlocks removeObjectForKey:applicationMetadata.applicationID];
    _launchingAppId = nil;
}

- (void)deviceManager:(GCKDeviceManager *)deviceManager didDisconnectFromApplicationWithError:(NSError *)error
{
    DLog(@"%@", error.localizedDescription);

    if (!_currentAppId)
        return;

    WebAppSession *webAppSession = [_sessions objectForKey:_currentAppId];

    if (!webAppSession || !webAppSession.delegate)
        return;

    [webAppSession.delegate webAppSessionDidDisconnect:webAppSession];
}

- (void)deviceManager:(GCKDeviceManager *)deviceManager didFailToConnectToApplicationWithError:(NSError *)error
{
    DLog(@"%@", error.localizedDescription);

    if (_launchingAppId)
    {
        FailureBlock failure = [_launchFailureBlocks objectForKey:_launchingAppId];

        if (failure)
            dispatch_on_main(^{ failure(error); });

        [_launchSuccessBlocks removeObjectForKey:_launchingAppId];
        [_launchFailureBlocks removeObjectForKey:_launchingAppId];
        _launchingAppId = nil;
    }
}

- (void)deviceManager:(GCKDeviceManager *)deviceManager didFailToConnectWithError:(NSError *)error
{
    DLog(@"%@", error.localizedDescription);

    if (self.connected)
        [self disconnect];
    else
        dispatch_on_main(^{ [self.delegate deviceService:self didFailConnectWithError:error]; });
}

- (void)deviceManager:(GCKDeviceManager *)deviceManager didFailToStopApplicationWithError:(NSError *)error
{
    DLog(@"%@", error.localizedDescription);
    //dispatch_on_main(^{ [self.delegate deviceService:self didFailConnectWithError:error]; });
}

- (void)deviceManager:(GCKDeviceManager *)deviceManager didReceiveApplicationMetadata:(GCKApplicationMetadata *)applicationMetadata
{
    DLog(@"%@", applicationMetadata);

    _currentAppId = applicationMetadata.applicationID;
}

- (void)deviceManager:(GCKDeviceManager *)deviceManager volumeDidChangeToLevel:(float)volumeLevel isMuted:(BOOL)isMuted
{
    DLog(@"volume: %f isMuted: %d", volumeLevel, isMuted);

    _currentVolumeLevel = volumeLevel;
    _currentMuteStatus = isMuted;

    [_subscriptions enumerateObjectsUsingBlock:^(ServiceSubscription *subscription, NSUInteger idx, BOOL *stop)
    {
        NSString *eventName = (NSString *) subscription.payload;

        if (eventName)
        {
            if ([eventName isEqualToString:kCastServiceVolumeSubscriptionName])
            {
                [subscription.successCalls enumerateObjectsUsingBlock:^(id success, NSUInteger successIdx, BOOL *successStop)
                {
                    VolumeSuccessBlock volumeSuccess = (VolumeSuccessBlock) success;

                    if (volumeSuccess)
                        dispatch_on_main(^{ volumeSuccess(volumeLevel); });
                }];
            }

            if ([eventName isEqualToString:kCastServiceMuteSubscriptionName])
            {
                [subscription.successCalls enumerateObjectsUsingBlock:^(id success, NSUInteger successIdx, BOOL *successStop)
                {
                    MuteSuccessBlock muteSuccess = (MuteSuccessBlock) success;

                    if (muteSuccess)
                        dispatch_on_main(^{ muteSuccess(isMuted); });
                }];
            }
        }
    }];
}

- (void)deviceManager:(GCKDeviceManager *)deviceManager didDisconnectWithError:(NSError *)error
{
    DLog(@"%@", error.localizedDescription);

    self.connected = NO;
    
    _castMediaControlChannel.delegate = nil;
    _castMediaControlChannel = nil;
    _castDeviceManager = nil;

    dispatch_on_main(^{ [self.delegate deviceService:self disconnectedWithError:error]; });
}

#pragma mark - Media Player

- (id<MediaPlayer>)mediaPlayer
{
    return self;
}

- (CapabilityPriorityLevel)mediaPlayerPriority
{
    return CapabilityPriorityLevelHigh;
}

- (void)displayImage:(NSURL *)imageURL iconURL:(NSURL *)iconURL title:(NSString *)title description:(NSString *)description mimeType:(NSString *)mimeType success:(MediaPlayerDisplaySuccessBlock)success failure:(FailureBlock)failure
{
    GCKMediaMetadata *metaData = [[GCKMediaMetadata alloc] initWithMetadataType:GCKMediaMetadataTypePhoto];
    [metaData setString:title forKey:kGCKMetadataKeyTitle];
    [metaData setString:description forKey:kGCKMetadataKeySubtitle];

    if (iconURL)
    {
        GCKImage *iconImage = [[GCKImage alloc] initWithURL:iconURL width:100 height:100];
        [metaData addImage:iconImage];
    }

    GCKMediaInformation *mediaInformation = [[GCKMediaInformation alloc] initWithContentID:imageURL.absoluteString streamType:GCKMediaStreamTypeNone contentType:mimeType metadata:metaData streamDuration:0 customData:nil];

    [self playMedia:mediaInformation webAppId:self.receiverAppId success:^(MediaLaunchObject *mediaLanchObject) {
        success(mediaLanchObject.session,mediaLanchObject.mediaControl);
    } failure:failure];
}

- (void) displayImage:(MediaInfo *)mediaInfo
              success:(MediaPlayerDisplaySuccessBlock)success
              failure:(FailureBlock)failure
{
    NSURL *iconURL;
    if(mediaInfo.images){
        ImageInfo *imageInfo = [mediaInfo.images firstObject];
        iconURL = imageInfo.url;
    }
    
    [self displayImage:mediaInfo.url iconURL:iconURL title:mediaInfo.title description:mediaInfo.description mimeType:mediaInfo.mimeType success:success failure:failure];
}

- (void) displayImageWithMediaInfo:(MediaInfo *)mediaInfo success:(MediaPlayerSuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *iconURL;
    if(mediaInfo.images){
        ImageInfo *imageInfo = [mediaInfo.images firstObject];
        iconURL = imageInfo.url;
    }
    
    GCKMediaMetadata *metaData = [[GCKMediaMetadata alloc] initWithMetadataType:GCKMediaMetadataTypePhoto];
    [metaData setString:mediaInfo.title forKey:kGCKMetadataKeyTitle];
    [metaData setString:mediaInfo.description forKey:kGCKMetadataKeySubtitle];
    
    if (iconURL)
    {
        GCKImage *iconImage = [[GCKImage alloc] initWithURL:iconURL width:100 height:100];
        [metaData addImage:iconImage];
    }
    
    GCKMediaInformation *mediaInformation = [[GCKMediaInformation alloc] initWithContentID:mediaInfo.url.absoluteString streamType:GCKMediaStreamTypeNone contentType:mediaInfo.mimeType metadata:metaData streamDuration:0 customData:nil];
    
    [self playMedia:mediaInformation webAppId:self.receiverAppId success:success failure:failure];
}

- (void) playMedia:(NSURL *)videoURL iconURL:(NSURL *)iconURL title:(NSString *)title description:(NSString *)description mimeType:(NSString *)mimeType shouldLoop:(BOOL)shouldLoop success:(MediaPlayerDisplaySuccessBlock)success failure:(FailureBlock)failure
{
    GCKMediaMetadata *metaData = [[GCKMediaMetadata alloc] initWithMetadataType:GCKMediaMetadataTypeMovie];
    [metaData setString:title forKey:kGCKMetadataKeyTitle];
    [metaData setString:description forKey:kGCKMetadataKeySubtitle];

    if (iconURL)
    {
        GCKImage *iconImage = [[GCKImage alloc] initWithURL:iconURL width:100 height:100];
        [metaData addImage:iconImage];
    }

    GCKMediaInformation *mediaInformation = [[GCKMediaInformation alloc] initWithContentID:videoURL.absoluteString streamType:GCKMediaStreamTypeBuffered contentType:mimeType metadata:metaData streamDuration:1000 customData:nil];

    [self playMedia:mediaInformation webAppId:self.receiverAppId success:^(MediaLaunchObject *mediaLanchObject) {
        success(mediaLanchObject.session,mediaLanchObject.mediaControl);
    } failure:failure];
}

- (void) playMedia:(MediaInfo *)mediaInfo shouldLoop:(BOOL)shouldLoop success:(MediaPlayerDisplaySuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *iconURL;
    if(mediaInfo.images){
        ImageInfo *imageInfo = [mediaInfo.images firstObject];
        iconURL = imageInfo.url;
    }
    [self playMedia:mediaInfo.url iconURL:iconURL title:mediaInfo.title description:mediaInfo.description mimeType:mediaInfo.mimeType shouldLoop:shouldLoop success:success failure:failure];
}

- (void) playMediaWithMediaInfo:(MediaInfo *)mediaInfo shouldLoop:(BOOL)shouldLoop success:(MediaPlayerSuccessBlock)success failure:(FailureBlock)failure{
    NSURL *iconURL;
    if(mediaInfo.images){
        ImageInfo *imageInfo = [mediaInfo.images firstObject];
        iconURL = imageInfo.url;
    }
    
    GCKMediaMetadata *metaData = [[GCKMediaMetadata alloc] initWithMetadataType:GCKMediaMetadataTypeMovie];
    [metaData setString:mediaInfo.title forKey:kGCKMetadataKeyTitle];
    [metaData setString:mediaInfo.description forKey:kGCKMetadataKeySubtitle];
    
    if (iconURL)
    {
        GCKImage *iconImage = [[GCKImage alloc] initWithURL:iconURL width:100 height:100];
        [metaData addImage:iconImage];
    }
    
    GCKMediaInformation *mediaInformation = [[GCKMediaInformation alloc] initWithContentID:mediaInfo.url.absoluteString streamType:GCKMediaStreamTypeBuffered contentType:mediaInfo.mimeType metadata:metaData streamDuration:1000 customData:nil];
    
    [self playMedia:mediaInformation webAppId:self.receiverAppId success:success failure:failure];
}

- (void) playMediaWithMediaInfo:(MediaInfo *)mediaInfo shouldLoop:(BOOL)shouldLoop atPosition:(NSTimeInterval)startPosition success:(MediaPlayerSuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *iconURL;
    if(mediaInfo.images){
        ImageInfo *imageInfo = [mediaInfo.images firstObject];
        iconURL = imageInfo.url;
    }
    
    GCKMediaMetadata *metaData = [[GCKMediaMetadata alloc] initWithMetadataType:GCKMediaMetadataTypeMovie];
    [metaData setString:mediaInfo.title forKey:kGCKMetadataKeyTitle];
    [metaData setString:mediaInfo.description forKey:kGCKMetadataKeySubtitle];
    
    if (iconURL)
    {
        GCKImage *iconImage = [[GCKImage alloc] initWithURL:iconURL width:100 height:100];
        [metaData addImage:iconImage];
    }
    
    GCKMediaInformation *mediaInformation = [[GCKMediaInformation alloc] initWithContentID:mediaInfo.url.absoluteString streamType:GCKMediaStreamTypeBuffered contentType:mediaInfo.mimeType metadata:metaData streamDuration:1000 customData:mediaInfo.customData];
    
    //_loadCustomData = mediaInfo.customDataForLoad;
    
    [self playMedia:mediaInformation webAppId:self.receiverAppId atPosition:startPosition success:success failure:failure];
}

- (void) playMedia:(GCKMediaInformation *)mediaInformation webAppId:(NSString *)mediaAppId success:(MediaPlayerSuccessBlock)success failure:(FailureBlock)failure
{
    [self playMedia:mediaInformation webAppId:mediaAppId atPosition:0 success:success failure:failure];
}

- (void) playMedia:(GCKMediaInformation *)mediaInformation webAppId:(NSString *)mediaAppId atPosition:(NSTimeInterval)startPosition success:(MediaPlayerSuccessBlock)success failure:(FailureBlock)failure
{
    WebAppLaunchSuccessBlock webAppLaunchBlock = ^(WebAppSession *webAppSession)
    {
        NSInteger result = [_castMediaControlChannel loadMedia:mediaInformation autoplay:YES playPosition:startPosition];

        if (result == kGCKInvalidRequestID)
        {
            if (failure)
                failure([ConnectError generateErrorWithCode:ConnectStatusCodeTvError andDetails:nil]);
        } else
        {
            webAppSession.launchSession.sessionType = LaunchSessionTypeMedia;

            _castMediaControlChannel.delegate = (CastWebAppSession *) webAppSession;

            if (success){
                    MediaLaunchObject *launchObject = [[MediaLaunchObject alloc] initWithLaunchSession:webAppSession.launchSession andMediaControl:webAppSession.mediaControl];
                    success(launchObject);
            }
        }
    };

    _launchingAppId = mediaAppId;

    [_launchSuccessBlocks setObject:webAppLaunchBlock forKey:mediaAppId];

    if (failure)
        [_launchFailureBlocks setObject:failure forKey:mediaAppId];

    BOOL result = [_castDeviceManager launchApplication:mediaAppId relaunchIfRunning:NO];

//    if (!result)
//    {
//        [_launchSuccessBlocks removeObjectForKey:mediaAppId];
//        [_launchFailureBlocks removeObjectForKey:mediaAppId];
//
//        if (failure)
//            failure([ConnectError generateErrorWithCode:ConnectStatusCodeTvError andDetails:nil]);
//    }
}

- (void)closeMedia:(LaunchSession *)launchSession success:(SuccessBlock)success failure:(FailureBlock)failure
{
    BOOL result = [_castDeviceManager stopApplicationWithSessionID:launchSession.sessionId];

    if (result)
    {
        if (success)
            success(nil);
    } else
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeTvError andDetails:nil]);
    }
}

#pragma mark - Media Control

- (id<MediaControl>)mediaControl
{
    return self;
}

- (CapabilityPriorityLevel)mediaControlPriority
{
    return CapabilityPriorityLevelHigh;
}

- (void)playWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    NSInteger result;

    @try
    {
        result = [_castMediaControlChannel play];
    } @catch (NSException *exception)
    {
        // this exception will be caught when trying to send command with no video
        result = kGCKInvalidRequestID;
    }

    if (result == kGCKInvalidRequestID)
    {
        if (failure)
            failure(nil);
    } else
    {
        if (success)
            success(nil);
    }
}

- (void)pauseWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    NSInteger result;

    @try
    {
        result = [_castMediaControlChannel pause];
    } @catch (NSException *exception)
    {
        // this exception will be caught when trying to send command with no video
        result = kGCKInvalidRequestID;
    }

    if (result == kGCKInvalidRequestID)
    {
        if (failure)
            failure(nil);
    } else
    {
        if (success)
            success(nil);
    }
}

- (void)stopWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    NSInteger result;

    @try
    {
        result = [_castMediaControlChannel stop];
    } @catch (NSException *exception)
    {
        // this exception will be caught when trying to send command with no video
        result = kGCKInvalidRequestID;
    }

    if (result == kGCKInvalidRequestID)
    {
        if (failure)
            failure(nil);
    } else
    {
        if (success)
            success(nil);
    }
}

- (void)rewindWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    if (failure)
        failure([ConnectError generateErrorWithCode:ConnectStatusCodeNotSupported andDetails:nil]);
}

- (void)fastForwardWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    if (failure)
        failure([ConnectError generateErrorWithCode:ConnectStatusCodeNotSupported andDetails:nil]);
}


#pragma mark - WebAppLauncher

- (id<WebAppLauncher>)webAppLauncher
{
    return self;
}

- (CapabilityPriorityLevel)webAppLauncherPriority
{
    return CapabilityPriorityLevelHigh;
}

- (NSString*) webAppId
{
    return self.receiverAppId;
}

- (void) launchWebAppWithSuccess:(WebAppLaunchSuccessBlock)success andFailure:(FailureBlock)failure
{
    [self launchWebApp:self.webAppId relaunchIfRunning:NO success:success failure:failure];
}

- (void)launchWebApp:(NSString *)webAppId success:(WebAppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    [self launchWebApp:webAppId relaunchIfRunning:YES success:success failure:failure];
}

- (void)launchWebApp:(NSString *)webAppId relaunchIfRunning:(BOOL)relaunchIfRunning success:(WebAppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    [_launchSuccessBlocks removeObjectForKey:webAppId];
    [_launchFailureBlocks removeObjectForKey:webAppId];

    if (success)
        [_launchSuccessBlocks setObject:success forKey:webAppId];

    if (failure)
        [_launchFailureBlocks setObject:failure forKey:webAppId];

    _launchingAppId = webAppId;

    BOOL result = [_castDeviceManager launchApplication:webAppId relaunchIfRunning:relaunchIfRunning];

    if (!result)
    {
        [_launchSuccessBlocks removeObjectForKey:webAppId];
        [_launchFailureBlocks removeObjectForKey:webAppId];
        _launchingAppId = nil;

        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeTvError andDetails:@"Could not detect if web app launched -- make sure you have the Google Cast Receiver JavaScript file in your web app"]);
    }
}

- (void)launchWebApp:(NSString *)webAppId params:(NSDictionary *)params success:(WebAppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    if (failure)
        failure([ConnectError generateErrorWithCode:ConnectStatusCodeNotSupported andDetails:nil]);
}

- (void)launchWebApp:(NSString *)webAppId params:(NSDictionary *)params relaunchIfRunning:(BOOL)relaunchIfRunning success:(WebAppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    if (failure)
        failure([ConnectError generateErrorWithCode:ConnectStatusCodeNotSupported andDetails:nil]);
}

- (void)joinWebApp:(LaunchSession *)webAppLaunchSession success:(WebAppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    WebAppLaunchSuccessBlock mySuccess = ^(WebAppSession *webAppSession)
    {
        SuccessBlock joinSuccess = ^(id responseObject)
        {
            if (success)
                success(webAppSession);
        };

        [webAppSession connectWithSuccess:joinSuccess failure:failure];
    };

    [_launchSuccessBlocks setObject:mySuccess forKey:webAppLaunchSession.appId];

    if (failure)
        [_launchFailureBlocks setObject:failure forKey:webAppLaunchSession.appId];

    _launchingAppId = webAppLaunchSession.appId;

    BOOL result = [_castDeviceManager joinApplication:webAppLaunchSession.appId];

    if (!result)
    {
        [_launchSuccessBlocks removeObjectForKey:webAppLaunchSession.appId];
        [_launchFailureBlocks removeObjectForKey:webAppLaunchSession.appId];
        _launchingAppId = nil;

        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeTvError andDetails:@"Could not detect if web app launched -- make sure you have the Google Cast Receiver JavaScript file in your web app"]);
    }
}

- (void) joinWebAppWithId:(NSString *)webAppId success:(WebAppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    LaunchSession *launchSession = [LaunchSession launchSessionForAppId:webAppId];
    launchSession.sessionType = LaunchSessionTypeWebApp;
    launchSession.service = self;

    [self joinWebApp:launchSession success:success failure:failure];
}

- (void)closeWebApp:(LaunchSession *)launchSession success:(SuccessBlock)success failure:(FailureBlock)failure
{
    BOOL result = [self.castDeviceManager stopApplicationWithSessionID:launchSession.sessionId];

    if (result)
    {
        if (success)
            success(nil);
    } else
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeTvError andDetails:nil]);
    }
}

-(void)pinWebApp:(LaunchSession *)launchSession success:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self sendNotSupportedFailure:failure];
}

-(void)unPinWebApp:(NSString *)webAppId success:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self sendNotSupportedFailure:failure];
}

- (void)isWebAppPinned:(NSString *)webAppId success:(WebAppPinStatusBlock)success failure:(FailureBlock)failure
{
    [self sendNotSupportedFailure:failure];
}

- (ServiceSubscription *)subscribeIsWebAppPinned:(NSString*)webAppId success:(WebAppPinStatusBlock)success failure:(FailureBlock)failure
{
    [self sendNotSupportedFailure:failure];
    return nil;
}

#pragma mark - Volume Control

- (id <VolumeControl>)volumeControl
{
    return self;
}

- (CapabilityPriorityLevel)volumeControlPriority
{
    return CapabilityPriorityLevelHigh;
}

- (void)volumeUpWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self getVolumeWithSuccess:^(float volume)
    {
        if (volume >= 1.0)
        {
            if (success)
                success(nil);
        } else
        {
            float newVolume = volume + 0.01;

            if (newVolume > 1.0)
                newVolume = 1.0;

            [self setVolume:newVolume success:success failure:failure];
        }
    } failure:failure];
}

- (void)volumeDownWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self getVolumeWithSuccess:^(float volume)
    {
        if (volume <= 0.0)
        {
            if (success)
                success(nil);
        } else
        {
            float newVolume = volume - 0.01;

            if (newVolume < 0.0)
                newVolume = 0.0;

            [self setVolume:newVolume success:success failure:failure];
        }
    } failure:failure];
}

- (void)setMute:(BOOL)mute success:(SuccessBlock)success failure:(FailureBlock)failure
{
    NSInteger result = [self.castDeviceManager setMuted:mute];

    if (result == kGCKInvalidRequestID)
    {
        if (failure)
            [ConnectError generateErrorWithCode:ConnectStatusCodeTvError andDetails:nil];
    } else
    {
        [self.castDeviceManager requestDeviceStatus];

        if (success)
            success(nil);
    }
}

- (void)getMuteWithSuccess:(MuteSuccessBlock)success failure:(FailureBlock)failure
{
    if (_currentMuteStatus)
    {
        if (success)
            success(_currentMuteStatus);
    } else
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeTvError andDetails:@"Cannot get this information without media loaded"]);
    }
}

- (ServiceSubscription *)subscribeMuteWithSuccess:(MuteSuccessBlock)success failure:(FailureBlock)failure
{
    if (_currentMuteStatus)
    {
        if (success)
            success(_currentMuteStatus);
    }

    ServiceSubscription *subscription = [ServiceSubscription subscriptionWithDelegate:self target:nil payload:kCastServiceMuteSubscriptionName callId:[self getNextId]];
    [subscription addSuccess:success];
    [subscription addFailure:failure];
    [subscription subscribe];

    return subscription;
}

- (void)setVolume:(float)volume success:(SuccessBlock)success failure:(FailureBlock)failure
{
    NSInteger result;
    NSString *failureMessage;

    @try
    {
        result = [self.castDeviceManager setVolume:volume];
    } @catch (NSException *ex)
    {
        // this is likely caused by having no active media session
        result = kGCKInvalidRequestID;
        failureMessage = @"There is no active media session to set volume on";
    }

    if (result == kGCKInvalidRequestID)
    {
        if (failure)
            [ConnectError generateErrorWithCode:ConnectStatusCodeTvError andDetails:failureMessage];
    } else
    {
        [self.castDeviceManager requestDeviceStatus];

        if (success)
            success(nil);
    }
}

- (void)getVolumeWithSuccess:(VolumeSuccessBlock)success failure:(FailureBlock)failure
{
    if (_currentVolumeLevel)
    {
        if (success)
            success(_currentVolumeLevel);
    } else
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeTvError andDetails:@"Cannot get this information without media loaded"]);
    }
}

- (ServiceSubscription *)subscribeVolumeWithSuccess:(VolumeSuccessBlock)success failure:(FailureBlock)failure
{
    if (_currentVolumeLevel)
    {
        if (success)
            success(_currentVolumeLevel);
    }

    ServiceSubscription *subscription = [ServiceSubscription subscriptionWithDelegate:self target:nil payload:kCastServiceVolumeSubscriptionName callId:[self getNextId]];
    [subscription addSuccess:success];
    [subscription addFailure:failure];
    [subscription subscribe];

    [self.castDeviceManager requestDeviceStatus];

    return subscription;
}

@end
