//
//  AppDelegate.m
//  StarterKit
//
//  Created by Harry Ng on 14/7/14.
//  Copyright (c) 2014 Request. All rights reserved.
//

#import "AppDelegate.h"

static NSString * const mobileAddress = @"http://www.homesmartly.com";
static NSString * const apiAddress = @"http://api.homesmartly.com";
static NSString * const appKey = @"b7e2d9d6cc333ebef267b882";

#define kGetBeacons @"/api/mobile_apps"
#define kPostToken @"/api/push_tokens"

#define kRequestActivity @"/api/logs"
#define kRequestMember @"/api/members"


@interface AppDelegate () <BeaconNotificationDelegate> {
    UIWebView *webView;
    bool showWebView;
    NSTimer *timer;
}

@end

@implementation AppDelegate
            

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    self.beacon = [Beacon new];
    self.beacon.delegate = self;
    
    // Get data from API
    [self.beacon getBeacons:[NSString stringWithFormat:@"%@%@/%@", apiAddress, kGetBeacons, appKey]];
    
    UIApplication *app = [UIApplication sharedApplication];
    if ([app respondsToSelector:@selector(registerForRemoteNotifications)]) {
        UIUserNotificationType types = UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
        [app registerUserNotificationSettings:settings];
        [app registerForRemoteNotifications];
    } else {
        [app registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
    }
    
    [self clearNotifications];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:@"ActivateWebView" object:nil queue:nil usingBlock:^(NSNotification *note) {
        [self activateWebView];
    }];
    [[NSNotificationCenter defaultCenter] addObserverForName:@"DeactivateWebView" object:nil queue:nil usingBlock:^(NSNotification *note) {
        [self deactivateWebView];
    }];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    if ([defs objectForKey:@"open_url_when_active"] != nil) {
        NSString *key = [defs objectForKey:@"open_url_when_active"];
        [self prepareWebView];
        [self popWebView:key];
        [defs removeObjectForKey:@"open_url_when_active"];
    }
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - Remote Notification

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
{
    UIUserNotificationType allowedTypes = [notificationSettings types];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    NSLog(@"My token is: %@", deviceToken);
    
    // Prepare the Device Token for Registration (remove spaces and  < >)
    NSString *devToken = [[[[deviceToken description]
                            stringByReplacingOccurrencesOfString:@"<"withString:@""] stringByReplacingOccurrencesOfString:@">" withString:@""]
                          stringByReplacingOccurrencesOfString: @" " withString: @""];
    
    NSLog(@"My Device token is: %@", devToken);
    
    [AppDelegate sendToken:devToken];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    NSLog(@"Failed to get token, error: %@", error);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    NSLog(@"didReceiveRemoteNotification");
    [self clearNotifications];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    NSLog(@"didReceiveRemoteNotification fetchCompletionHandler");
    [self clearNotifications];
}

- (void) clearNotifications
{
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber: 0];
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
}

#pragma mark - WebView

- (void)popWebView:(NSString *)key
{
    NSLog(@"webView key: %@", key);
    
    if (showWebView && [[NSUserDefaults standardUserDefaults] objectForKey:key] != nil) {
        webView.hidden = NO;
        
        NSString *url = [[NSUserDefaults standardUserDefaults] objectForKey:key];
        [webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]]];
    }
    
}

- (void)close:(id)sender
{
    webView.hidden = YES;
}

- (void)prepareWebView
{
    if (webView == nil) {
        showWebView = YES;
        
        CGRect screenFrame = [[UIScreen mainScreen] bounds];
        webView = [[UIWebView alloc] initWithFrame:screenFrame];
        
        UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        closeButton.frame = CGRectMake(10, 40, 50, 50);
        [closeButton setImage:[UIImage imageNamed:@"close"] forState:UIControlStateNormal];
        [closeButton addTarget:self action:@selector(close:) forControlEvents:UIControlEventTouchUpInside];
        [webView addSubview:closeButton];
        
        [self.window makeKeyAndVisible];
        [self.window addSubview:webView];
        
        webView.hidden = YES;
    }
}

- (void)activateWebView
{
    showWebView = YES;
}

- (void)deactivateWebView
{
    showWebView = NO;
}

- (void)notifyWhenEntryBeacon:(CLBeaconRegion *)beaconRegion
{
    NSString *key = [NSString stringWithFormat:@"%@-%@-%@-%@-%@", @"enter", @"url", [beaconRegion.proximityUUID UUIDString], [beaconRegion major], [beaconRegion minor]];
    if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive) {
        [self prepareWebView];
        
        double delayInSeconds = 2.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            if (webView.hidden == YES) {
                [self popWebView:key];
            }
        });
    } else {
        [[NSUserDefaults standardUserDefaults] setObject:key forKey:@"open_url_when_active"];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"Entry" object:nil];
    
    NSLog(@"detect beacon %@", beaconRegion);
    
    NSString *message_key = [NSString stringWithFormat:@"message-%@-%@-%@", [beaconRegion.proximityUUID UUIDString], beaconRegion.major, beaconRegion.minor];
    [self checkLocalNotificationWithKey:message_key];
    
    [AppDelegate sendData:[beaconRegion proximityUUID] major:[beaconRegion major] minor:[beaconRegion minor]];
}

- (void)notifyWhenExitBeacon:(CLBeaconRegion *)beaconRegion
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"Exit" object:nil];
    
    NSLog(@"detect beacon %@", beaconRegion);
}

- (void)notifyWhenImmediate:(CLBeacon *)beacon
{
    NSDictionary *dict = [NSDictionary dictionaryWithObject:beacon forKey:@"zone"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"Immediate" object:nil userInfo:dict];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"Range" object:nil userInfo:dict];
    
    if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive) {
        [self prepareWebView];
        
        if (webView.hidden == YES) {
            double delayInSeconds = 2.0;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                NSString *key = [NSString stringWithFormat:@"%@-%@-%@-%@-%@", @"immediate", @"url", [beacon.proximityUUID UUIDString], [beacon major], [beacon minor]];
                [self popWebView:key];
            });
        }
    }
    
}

- (void)notifyWhenNear:(CLBeacon *)beacon
{
    NSDictionary *dict = [NSDictionary dictionaryWithObject:beacon forKey:@"zone"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"Near" object:nil userInfo:dict];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"Range" object:nil userInfo:dict];
    
    if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive) {
        [self prepareWebView];
        
        if (webView.hidden == YES) {
            double delayInSeconds = 2.0;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                NSString *key = [NSString stringWithFormat:@"%@-%@-%@-%@-%@", @"near", @"url", [beacon.proximityUUID UUIDString], [beacon major], [beacon minor]];
                [self popWebView:key];
            });
        }
    }
    
}

- (void)notifyWhenFar:(CLBeacon *)beacon
{
    NSDictionary *dict = [NSDictionary dictionaryWithObject:beacon forKey:@"zone"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"Far" object:nil userInfo:dict];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"Range" object:nil userInfo:dict];
    
    if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive) {
        [self prepareWebView];
        
        if (webView.hidden == YES) {
            double delayInSeconds = 2.0;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                NSString *key = [NSString stringWithFormat:@"%@-%@-%@-%@-%@", @"far", @"url", [beacon.proximityUUID UUIDString], [beacon major], [beacon minor]];
                [self popWebView:key];
            });
        }
    }
    
}

#pragma mark - Local notifications
- (void)checkLocalNotificationWithKey:(NSString *)key
{
    if ([[NSUserDefaults standardUserDefaults] objectForKey:key] != nil) {
        [self sendLocalNotificationWithMessage:[[NSUserDefaults standardUserDefaults] objectForKey:key]];
    }
}

- (void)sendLocalNotificationWithMessage:(NSString*)message
{
    UILocalNotification *notification = [UILocalNotification new];
    
    // Notification details
    notification.alertBody = message;
    // notification.alertBody = [NSString stringWithFormat:@"Entered beacon region for UUID: %@",
    //                         region.proximityUUID.UUIDString];   // Major and minor are not available at the monitoring stage
    notification.alertAction = NSLocalizedString(@"View Details", nil);
    notification.soundName = UILocalNotificationDefaultSoundName;
    
    if ([notification respondsToSelector:@selector(regionTriggersOnce)]) {
        notification.regionTriggersOnce = YES;
    }
    
    if (timer == nil) {
        [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
        
        timer = [NSTimer timerWithTimeInterval:60 target:self selector:@selector(turnOnLocal) userInfo:nil repeats:NO];
    }
}

- (void)turnOnLocal
{
    [timer invalidate];
    timer = nil;
}

+ (void)sendData:(NSUUID *)beaconId major:(NSNumber *)kMajor minor:(NSNumber *)kMinor
{
    NSLog(@"sending data...");
    
    NSNumber *time = [NSNumber numberWithLongLong:[[NSDate date] timeIntervalSince1970] * 1000];
    
    NSString *deviceId = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    
    NSArray *objects = [NSArray arrayWithObjects:[beaconId UUIDString], [kMajor stringValue], [kMinor stringValue], deviceId, appKey, time, nil];
    NSArray *keys = [NSArray arrayWithObjects:@"uuid", @"major", @"minor", @"deviceId", @"appKey", @"time", nil];
    NSDictionary *jsonDict = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
    
    NSError *error;
    NSData *requestData = [NSJSONSerialization dataWithJSONObject:jsonDict
                                                          options:NSJSONWritingPrettyPrinted // Pass 0 if you don't care about the readability of the generated string
                                                            error:&error];
    NSString *jsonString = [[NSString alloc] initWithData:requestData encoding:NSUTF8StringEncoding];
    
    NSLog(@"jsonRequest is %@", jsonString);
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", apiAddress, kRequestActivity]];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
    
    
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[requestData length]] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody: requestData];
    
    NSURLConnection *connection = [[NSURLConnection alloc]initWithRequest:request delegate:self];
    if (connection) {
        [connection start];
    }
    
}

+ (void)sendToken:(NSString *)token
{
    NSLog(@"registering first time...");
    
    NSString *deviceId = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    
    NSArray *objects = [NSArray arrayWithObjects:appKey, deviceId, @"ios", token, nil];
    NSArray *keys = [NSArray arrayWithObjects:@"appKey", @"deviceId", @"pushType", @"pushToken", nil];
    NSDictionary *jsonDict = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
    
    NSError *error;
    NSData *requestData = [NSJSONSerialization dataWithJSONObject:jsonDict
                                                          options:NSJSONWritingPrettyPrinted // Pass 0 if you don't care about the readability of the generated string
                                                            error:&error];
    NSString *jsonString = [[NSString alloc] initWithData:requestData encoding:NSUTF8StringEncoding];
    
    NSLog(@"jsonRequest is %@", jsonString);
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", apiAddress, kPostToken]];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
    
    
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[requestData length]] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody: requestData];
    
    NSURLConnection *connection = [[NSURLConnection alloc]initWithRequest:request delegate:self];
    if (connection) {
        [connection start];
    }
    
}

@end
