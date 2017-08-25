//
//  AppDelegate.m
//  NetworkEye
//
//  Created by coderyi on 15/11/5.
//  Copyright © 2015年 coderyi. All rights reserved.
//

#import "AppDelegate.h"
#import "DemoViewController.h"
#import "NEHTTPEye.h"
#import "NetworkEye/NEHTTPModelManager.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
#if defined(DEBUG)||defined(_DEBUG)
    [NEHTTPEye setEnabled:YES];
#endif

    UINavigationController *nav=[[UINavigationController alloc] initWithRootViewController:[[DemoViewController alloc] init]];
    nav.navigationBar.barTintColor=[UIColor colorWithRed:0.24f green:0.51f blue:0.78f alpha:1.00f];
    nav.navigationBar.titleTextAttributes=[NSDictionary dictionaryWithObject:[UIColor whiteColor] forKey:NSForegroundColorAttributeName];
    self.window.rootViewController=nav;
    return YES;
}

@end
