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
    
    [[NSNotificationCenter defaultCenter] addObserverForName:@"Immediate" object:nil queue:nil usingBlock:^(NSNotification *note) {
        NSDictionary *dict = [note userInfo];
        CLBeacon *beacon = [dict objectForKey:@"zone"];
        NSString *key = [NSString stringWithFormat:@"%@-%@-%@-%@", @"floorplan", [beacon.proximityUUID UUIDString], [beacon major], [beacon minor]];
        NSString *value = [[NSUserDefaults standardUserDefaults] objectForKey:key];
        
        NSLog(@"area: %@", value);
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
    switch (motion) {
        case 0:
            self.imageView.center = CGPointMake(90, 160);
            break;
        case 1:
            self.imageView.center = CGPointMake(230, 160);
            break;
        case 2:
            self.imageView.center = CGPointMake(90, 330);
            break;
        case 3:
            self.imageView.center = CGPointMake(230, 330);
            break;
            
        default:
            break;
    }
}

@end
