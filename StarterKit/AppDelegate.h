//
//  AppDelegate.h
//  StarterKit
//
//  Created by Harry Ng on 14/7/14.
//  Copyright (c) 2014 Request. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Beacon.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) Beacon *beacon;

@end

