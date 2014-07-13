//
//  FirstViewController.m
//  StarterKit
//
//  Created by Harry Ng on 14/7/14.
//  Copyright (c) 2014 Request. All rights reserved.
//

#import "FirstViewController.h"

@interface FirstViewController () {
    id o1;
    id o2;
    id o3;
}

@end

@implementation FirstViewController
            
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidAppear:(BOOL)animated
{
    o1 = [[NSNotificationCenter defaultCenter] addObserverForName:@"Entry" object:nil queue:nil usingBlock:^(NSNotification *note) {
        self.locationLabel.text = @"Entered Region";
    }];
    o2 = [[NSNotificationCenter defaultCenter] addObserverForName:@"Exit" object:nil queue:nil usingBlock:^(NSNotification *note) {
        self.locationLabel.text = @"Exited Region";
    }];
    o3 = [[NSNotificationCenter defaultCenter] addObserverForName:@"Immediate" object:nil queue:nil usingBlock:^(NSNotification *note) {
        self.locationLabel.text = @"Immediate";
    }];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:o1];
    [[NSNotificationCenter defaultCenter] removeObserver:o2];
    [[NSNotificationCenter defaultCenter] removeObserver:o3];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
