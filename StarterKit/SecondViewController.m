//
//  SecondViewController.m
//  StarterKit
//
//  Created by Harry Ng on 14/7/14.
//  Copyright (c) 2014 Request. All rights reserved.
//

#import "SecondViewController.h"
#import <CoreLocation/CoreLocation.h>

@interface SecondViewController ()

@end

@implementation SecondViewController
            
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    
    self.zoneA.text = [defs objectForKey:@"area-name-A"];
    self.zoneB.text = [defs objectForKey:@"area-name-B"];
    self.zoneC.text = [defs objectForKey:@"area-name-C"];
    self.zoneD.text = [defs objectForKey:@"area-name-D"];
    
    NSURL *url = [NSURL URLWithString:@"http://api.homesmartly.com/"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
    
    
    [request setHTTPMethod:@"GET"];

    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        self.imageViewA.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[defs objectForKey:@"area-url-A"]]]];
        self.imageViewB.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[defs objectForKey:@"area-url-B"]]]];
        self.imageViewC.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[defs objectForKey:@"area-url-C"]]]];
        self.imageViewD.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[defs objectForKey:@"area-url-D"]]]];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:@"Range" object:nil queue:nil usingBlock:^(NSNotification *note) {
        NSDictionary *dict = [note userInfo];
        CLBeacon *beacon = [dict objectForKey:@"zone"];
        NSString *reach;
        if (beacon.proximity == CLProximityImmediate) {
            reach = @"immediate";
        } else if (beacon.proximity == CLProximityNear) {
            reach = @"near";
        } else if (beacon.proximity == CLProximityFar) {
            reach = @"far";
        }
        NSString *key = [NSString stringWithFormat:@"%@-%@-%@-%@-%@", reach, @"floorplan", [beacon.proximityUUID UUIDString], [beacon major], [beacon minor]];
        NSString *value = [[NSUserDefaults standardUserDefaults] objectForKey:key];
        
        NSLog(@">>> area: %@", value);
        if ([value isEqualToString:@"A"]) {
            [self move:0];
        } else if ([value isEqualToString:@"B"]) {
            [self move:1];
        } else if ([value isEqualToString:@"C"]) {
            [self move:2];
        } else if ([value isEqualToString:@"D"]) {
            [self move:3];
        }
    }];
}

- (void)viewDidAppear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"DeactivateWebView" object:nil];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ActivateWebView" object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)move:(int)motion
{
    self.imageViewA.hidden = YES;
    self.imageViewB.hidden = YES;
    self.imageViewC.hidden = YES;
    self.imageViewD.hidden = YES;
    switch (motion) {
        case 0:
            self.imageView.center = CGPointMake(90, 160);
            self.imageViewA.hidden = NO;
            break;
        case 1:
            self.imageView.center = CGPointMake(230, 160);
            self.imageViewB.hidden = NO;
            break;
        case 2:
            self.imageView.center = CGPointMake(90, 330);
            self.imageViewC.hidden = NO;
            break;
        case 3:
            self.imageView.center = CGPointMake(230, 330);
            self.imageViewD.hidden = NO;
            break;
            
        default:
            break;
    }
}

@end
