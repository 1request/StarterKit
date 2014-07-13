//
//  Beacon.h
//  StarterKit
//
//  Created by Harry Ng on 8/7/14.
//  Copyright (c) 2014 Request. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@protocol BeaconNotificationDelegate <NSObject>

- (void)notifyWhenEntryBeacon:(CLBeaconRegion*)beaconRegion;
- (void)notifyWhenExitBeacon:(CLBeaconRegion*)beaconRegion;

- (void)notifyWhenImmediate:(CLBeacon *)beacon;

@end

@interface Beacon : NSObject <CLLocationManagerDelegate>

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, assign) id<BeaconNotificationDelegate> delegate;

- (void)getBeacons:(NSString *)address;

@end
