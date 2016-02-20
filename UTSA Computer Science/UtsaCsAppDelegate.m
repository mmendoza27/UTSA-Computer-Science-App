//
//  UtsaCsAppDelegate.m
//  UTSA Computer Science
//
//  Created by Michael Mendoza on 1/24/14.
//  Copyright (c) 2014 University of Texas at San Antonio. All rights reserved.
//

#import <AudioToolbox/AudioToolbox.h>

#import "Reachability.h"
#import "UtsaCsAppDelegate.h"

@implementation UtsaCsAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    
    // Create a UUID that we can add to NSUserDefaults and utilize throughout the application.
    NSString *UUID = [[NSUserDefaults standardUserDefaults] objectForKey:@"UtsaCsUUID"];
    
    if (!UUID) {
        CFUUIDRef uuid = CFUUIDCreate(NULL);
        UUID = (__bridge_transfer NSString *)CFUUIDCreateString(NULL, uuid);
        UUID = [UUID stringByReplacingOccurrencesOfString:@"-" withString:@""];
        CFRelease(uuid);
        
        [[NSUserDefaults standardUserDefaults] setObject:UUID forKey:@"UtsaCsUUID"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    // Let the device know we want to receive push notifications
	[[UIApplication sharedApplication] registerForRemoteNotificationTypes:
     (UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
    
    application.applicationIconBadgeNumber = 0;
    
    // Set up the UI colors and appearance
    UIColor *utsaOrangeColor = [UIColor colorWithRed:244.0/255.0 green:115.0/255.0 blue:33.0/255.0 alpha:1.0];
    UIColor *utsaBlueColor = [UIColor colorWithRed:0.0/255.0 green:34.0/255.0 blue:68.0/255.0 alpha:1.0];
    
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName:utsaOrangeColor}];
    [[UINavigationBar appearance] setBarTintColor:utsaBlueColor];
    [[UITabBar appearance] setBarTintColor:utsaBlueColor];
    self.window.tintColor = utsaOrangeColor; 
    
    // Initialize Reachability
    Reachability *reachability = [Reachability reachabilityWithHostname:@"www.google.com"];
    
    // Start Monitoring
    [reachability startNotifier];

    return YES;
}

- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken
{
    #if !TARGET_IPHONE_SIMULATOR
    
    // Get Bundle Info for Remote Registration (handy if you have more than one app)
    NSString *appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];
    NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    
    // Check what Notifications the user has turned on.  We registered for all three, but they may have manually disabled some or all of them.
    NSUInteger remoteNotificationTypes = [[UIApplication sharedApplication] enabledRemoteNotificationTypes];
    
    // Set the defaults to disabled unless we find otherwise...
    NSString *pushBadge = @"disabled";
    NSString *pushAlert = @"disabled";
    NSString *pushSound = @"disabled";
    
    // Check what Registered Types are turned on. This is a bit tricky since if two are enabled, and one is off, it will return a number 2... not telling you which
    // one is actually disabled. So we are literally checking to see if rnTypes matches what is turned on, instead of by number. The "tricky" part is that the
    // single notification types will only match if they are the ONLY one enabled.  Likewise, when we are checking for a pair of notifications, it will only be
    // true if those two notifications are on.  This is why the code is written this way
    if(remoteNotificationTypes == UIRemoteNotificationTypeBadge){
        pushBadge = @"enabled";
    }
    else if(remoteNotificationTypes == UIRemoteNotificationTypeAlert){
        pushAlert = @"enabled";
    }
    else if(remoteNotificationTypes == UIRemoteNotificationTypeSound){
        pushSound = @"enabled";
    }
    else if(remoteNotificationTypes == ( UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert)){
        pushBadge = @"enabled";
        pushAlert = @"enabled";
    }
    else if(remoteNotificationTypes == ( UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound)){
        pushBadge = @"enabled";
        pushSound = @"enabled";
    }
    else if(remoteNotificationTypes == ( UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound)){
        pushAlert = @"enabled";
        pushSound = @"enabled";
    }
    else if(remoteNotificationTypes == ( UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound)){
        pushBadge = @"enabled";
        pushAlert = @"enabled";
        pushSound = @"enabled";
    }
    
    // Get the users Device Model, Display Name, Unique ID, Token & Version Number
    UIDevice *dev = [UIDevice currentDevice];
    NSString *deviceUuid = [[NSUserDefaults standardUserDefaults] stringForKey:@"UtsaCsUUID"];
    NSString *deviceName = dev.name;
    NSString *deviceModel = dev.model;
    NSString *deviceSystemVersion = dev.systemVersion;
    NSString *notificationPrefs = @"NULL";
    
    // Prepare the Device Token for Registration (remove spaces and < >)
    NSString *token = [[[[deviceToken description]
                               stringByReplacingOccurrencesOfString:@"<"withString:@""]
                              stringByReplacingOccurrencesOfString:@">" withString:@""]
                             stringByReplacingOccurrencesOfString: @" " withString: @""];
    
    // Build URL String for Registration
    NSString *host = @"162.209.104.58";
    NSString *urlString = [@"/pushNotifications/apns.php?"stringByAppendingString:@"task=register"];
    
    urlString = [urlString stringByAppendingString:@"&appname="];
    urlString = [urlString stringByAppendingString:appName];
    urlString = [urlString stringByAppendingString:@"&appversion="];
    urlString = [urlString stringByAppendingString:appVersion];
    urlString = [urlString stringByAppendingString:@"&notificationtypes="];
    urlString = [urlString stringByAppendingString:notificationPrefs];
    urlString = [urlString stringByAppendingString:@"&deviceuid="];
    urlString = [urlString stringByAppendingString:deviceUuid];
    urlString = [urlString stringByAppendingString:@"&devicetoken="];
    urlString = [urlString stringByAppendingString:token];
    urlString = [urlString stringByAppendingString:@"&devicename="];
    urlString = [urlString stringByAppendingString:deviceName];
    urlString = [urlString stringByAppendingString:@"&devicemodel="];
    urlString = [urlString stringByAppendingString:deviceModel];
    urlString = [urlString stringByAppendingString:@"&deviceversion="];
    urlString = [urlString stringByAppendingString:deviceSystemVersion];
    urlString = [urlString stringByAppendingString:@"&pushbadge="];
    urlString = [urlString stringByAppendingString:pushBadge];
    urlString = [urlString stringByAppendingString:@"&pushalert="];
    urlString = [urlString stringByAppendingString:pushAlert];
    urlString = [urlString stringByAppendingString:@"&pushsound="];
    urlString = [urlString stringByAppendingString:pushSound];
    
    // Register the Device Data
    // !!! CHANGE "http" TO "https" IF YOU ARE USING HTTPS PROTOCOL
    NSOperationQueue *otherQueue = [[NSOperationQueue alloc] init];
    NSURL *url = [[NSURL alloc] initWithScheme:@"http" host:host path:urlString];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
    
    [NSURLConnection sendAsynchronousRequest:request queue:otherQueue completionHandler:^(NSURLResponse *response, NSData *returnData, NSError *error)
    {
        if ([returnData length] == 0 && error == nil)
        {
            NSLog(@"Register URL: %@", url);
            NSLog(@"Return Data: %@", returnData);
            NSLog(@"My token is: %@", deviceToken);
        }
        // Check for possible error code from the sendAsynchronousRequest method. More details can be found here:
        // https://developer.apple.com/library/mac/#documentation/Networking/Reference/CFNetworkErrors/Reference/reference.html
        else if (error != nil && error.code == -1001)
        {
            NSLog(@"Error: The request timed out.");
        }
        else if (error != nil && error.code == -1003)
        {
            NSLog(@"Error: Could not find host.");
        }
        else if (error != nil && error.code == -1004)
        {
            NSLog(@"Error: Could not connect to host.");
        }
        else if (error != nil && error.code == -1005)
        {
            NSLog(@"Error: Network connection was lost.");
        }
    }];
    
    #endif
    
}

- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error
{
    #if !TARGET_IPHONE_SIMULATOR
	
    NSLog(@"Error on registration. Error: %@", error);
    
    #endif
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    #if !TARGET_IPHONE_SIMULATOR
	
    NSLog(@"Remote notification: %@",[userInfo description]);
    NSDictionary *apsInfo = [userInfo objectForKey:@"aps"];
    
    NSString *alert = [apsInfo objectForKey:@"alert"];
    NSLog(@"Received Push Alert: %@", alert);
    
    NSString *sound = [apsInfo objectForKey:@"sound"];
    NSLog(@"Received Push Sound: %@", sound);
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    
    NSString *badge = [apsInfo objectForKey:@"badge"];
    NSLog(@"Received Push Badge: %@", badge);
    application.applicationIconBadgeNumber = [[apsInfo objectForKey:@"badge"] integerValue];
    
    #endif
}

- (void)applicationWillResignActive:(UIApplication *)application
{
   // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
   // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
   // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
   // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
   // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
   // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
   // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
