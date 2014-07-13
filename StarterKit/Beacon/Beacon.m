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
                    if ([[action objectForKey:@"action"] isEqualToString:@"floorplan"]) {
                        NSString *key = [NSString stringWithFormat:@"%@-%@-%@-%@", @"floorplan", uuid, major, minor];
                        NSString *area = [action objectForKey:@"area"];
                        [defs setObject:area forKey:key];
                        break;
                    }
                    NSString *trigger = [action objectForKey:@"trigger"];
                    NSString *url = [action objectForKey:@"url"];
                    NSString *key = [NSString stringWithFormat:@"%@-%@-%@-%@", trigger, uuid, major, minor];
                    [defs setObject:url forKey:key];
                    NSLog(@"%@ -> %@", key, url);
                }
            }
            @catch (NSException *exception) {
                NSLog(@"exceptino: %@", exception);
            }
            @finally {
                
            }
            
            count++;
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
