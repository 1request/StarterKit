//
//  Beacon.m
//  StarterKit
//
//  Created by Harry Ng on 8/7/14.
//  Copyright (c) 2014 Request. All rights reserved.
//

#import "Beacon.h"

@implementation Beacon

#pragma mark - Beacon

- (void)getBeacons:(NSString *)address
{
    NSURL *url = [NSURL URLWithString:address];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
    
    
    [request setHTTPMethod:@"GET"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    
    // Start using dictionary
    [self createLocationManager];
    
    if (![CLLocationManager isMonitoringAvailableForClass:[CLBeaconRegion class]]) {
        NSLog(@"Couldn't turn on region monitoring: Region monitoring is not available for CLBeaconRegion class.");
        return;
    }
    
    if ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
        [self.locationManager requestAlwaysAuthorization];
    }
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        if (!data) {
            NSLog(@"%s: sendAynchronousRequest error: %@", __FUNCTION__, connectionError);
            return;
        } else {
            NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
            if (statusCode != 200) {
                NSLog(@"%s: sendAsynchronousRequest status code != 200: response = %@", __FUNCTION__, response);
                return;
            }
        }
        
        NSError *parseError = nil;
        NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseError];
        if (!dictionary) {
            NSLog(@"%s: JSONObjectWithData error: %@; data = %@", __FUNCTION__, parseError, [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
            return;
        }
        
        NSUserDefaults * defs = [NSUserDefaults standardUserDefaults];
        NSDictionary * dict = [defs dictionaryRepresentation];
        for (id key in dict) {
            [defs removeObjectForKey:key];
        }
        
        // Beacons
        NSArray *beaconArray = [dictionary objectForKey:@"beacons"];
        int count = 0;
        for (NSDictionary *object in beaconArray) {
            NSString *uuid = [object objectForKey:@"uuid"];
            NSString *major = [object objectForKey:@"major"];
            NSString *minor = [object objectForKey:@"minor"];
            
            NSUUID *proximityUUID = [[NSUUID alloc] initWithUUIDString:uuid];
            NSInteger kMajor = [major integerValue];
            NSInteger kMinor = [minor integerValue];
            
            NSLog(@"uuid -> %@ / major -> %@ / minor -> %@", uuid, major, minor);
            
            NSString *identifier = [NSString stringWithFormat:@"beacon-%d-%@-%@", count, major, minor];
            
            @try {
                CLBeaconRegion *beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:proximityUUID major:kMajor minor:kMinor identifier:identifier];
                beaconRegion.notifyEntryStateOnDisplay = YES;
                beaconRegion.notifyOnEntry = YES;
                beaconRegion.notifyOnExit = YES;
                
                [self.locationManager startRangingBeaconsInRegion:beaconRegion];
                [self.locationManager startMonitoringForRegion:beaconRegion];
                
                NSArray *actions = [object objectForKey:@"actions"];
                for (NSDictionary *action in actions) {
                    NSString *trigger = [action objectForKey:@"trigger"];
                    NSString *act = [action objectForKey:@"action"];
                    NSString *key = [NSString stringWithFormat:@"%@-%@-%@-%@-%@", trigger, act, uuid, major, minor];

                    if ([act isEqualToString:@"floorplan"]) {
                        [defs setObject:[action objectForKey:@"area"] forKey:key];
                    } else if ([act isEqualToString:@"image"]) {
                        key = [NSString stringWithFormat:@"%@-%@-%@-%@-%@", trigger, @"url", uuid, major, minor];
                        NSString *imageUrl = [NSString stringWithFormat:@"http://www.homesmartly.com%@", [action objectForKey:@"url"]];
                        [defs setObject:imageUrl forKey:key];
                    } else {
                        key = [NSString stringWithFormat:@"%@-%@-%@-%@-%@", trigger, @"url", uuid, major, minor];
                        [defs setObject:[action objectForKey:@"url"] forKey:key];
                    }
                    
                    key = [NSString stringWithFormat:@"message-%@-%@-%@", uuid, major, minor];
                    [defs setObject:[action objectForKey:@"message"] forKey:key];
                    
                    NSLog(@"%@ -> %@", key, [action objectForKey:@"message"]);
                }
            }
            @catch (NSException *exception) {
                NSLog(@"exceptino: %@", exception);
            }
            @finally {
                
            }
            
            count++;
        }
        
        // Areas
        NSArray *areaArray = [dictionary objectForKey:@"areas"];
        for (NSDictionary *object in areaArray) {
            @try {
                NSString *position = [object objectForKey:@"position"];
                NSString *name = [object objectForKey:@"name"];
                NSString *url = [NSString stringWithFormat:@"http://www.homesmartly.com%@", [object objectForKey:@"url"]];
                
                NSString *key = [NSString stringWithFormat:@"area-url-%@", position];
                [defs setObject:url forKey:key];
                key = [NSString stringWithFormat:@"area-name-%@", position];
                [defs setObject:name forKey:key];
            }
            @catch (NSException *exception) {
                NSLog(@"exceptino: %@", exception);
            }
            @finally {
                
            }
        }
        
        [defs synchronize];
    }];
}

- (void)createLocationManager
{
    if (!self.locationManager) {
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
    }
}

#pragma mark - Location manager delegate methods
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (![CLLocationManager locationServicesEnabled]) {
        NSLog(@"Couldn't turn on monitoring: Location services are not enabled.");
        return;
    }
    
    if ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorized) {
        NSLog(@"Couldn't turn on monitoring: Location services not authorised.");
    }
    
    if ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorizedAlways) {
        NSLog(@"Couldn't turn on monitoring: Location services (Always) not authorised.");
        return;
    }
    
}

- (void)locationManager:(CLLocationManager *)manager
        didRangeBeacons:(NSArray *)beacons
               inRegion:(CLBeaconRegion *)region {
    
    NSLog(@"%s Range region: %@ with beacons %@",__PRETTY_FUNCTION__ ,region , beacons);
    
    for (CLBeacon *b in beacons) {
        if (b.proximity == CLProximityImmediate) {
            [self.delegate notifyWhenImmediate:b];
        } else if (b.proximity == CLProximityNear) {
            [self.delegate notifyWhenNear:b];
        } else if (b.proximity == CLProximityFar) {
            [self.delegate notifyWhenFar:b];
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLBeaconRegion *)region
{
    NSLog(@"Entered region: %@", region);
    
    if (self.delegate) {
        [self.delegate notifyWhenEntryBeacon:region];
    }
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLBeaconRegion *)region
{
    NSLog(@"Exited region: %@", region);
    
    if (self.delegate) {
        [self.delegate notifyWhenExitBeacon:region];
    }
}

- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
{
    NSString *stateString = nil;
    switch (state) {
        case CLRegionStateInside:
            stateString = @"inside";
            break;
        case CLRegionStateOutside:
            stateString = @"outside";
            break;
        case CLRegionStateUnknown:
            stateString = @"unknown";
            break;
    }
    NSLog(@"State changed to %@ for region %@.", stateString, region);
    
    
}

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLBeaconRegion *)region withError:(NSError *)error
{
    NSString *message = [NSString stringWithFormat:@"error: %@ / region: %@", [error description], region.minor];
    NSLog(@"%@", message);
}

@end
