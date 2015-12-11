//
//  OCSChromecastControllerDelegate.h
//  OCS GO
//
//  Created by Fabien BOURDON on 27/06/2014.
//  Copyright (c) 2014 Rémi ROCARIES. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ConnectableDevice;
/**
 * The delegate to ChromecastDeviceController. Allows responsding to device and
 * media states and reflecting that in the UI.
 */
@protocol ConnectCastManagerDelegate<NSObject>

/**
 * Called when cast devices are discoverd on the network.
 */
- (void)castManagerDidDiscoverDeviceOnNetwork;

/**
 * Called when connection to the device was established.
 *
 * @param device The device to which the connection was established.
 */
- (void)castManagerDidConnectToDevice:(ConnectableDevice*)device;

/**
 * Called when connection to the device was closed.
 */
- (void)castManagerDidDisconnect;

/**
 * Called when the playback state of media on the device changes.
 */
- (void)castManagerDidReceiveMediaStateChange;

/**
 * Called to display the modal device selection view controller from the cast icon.
 */
- (void)castManagerShouldDisplayModalDeviceSelectionController;

/**
 * Called to display the modal device view controller from the cast icon.
 */
- (void)castManagerShouldDisplayModalDeviceController;

/**
 * Called to display the remote media playback view controller.
 */
- (void)castManagerShouldPresentPlaybackController;


/**
 * Called to display the remote media playback view controller.
 */
- (void)castManagerShouldPresentTracksController;


@end
