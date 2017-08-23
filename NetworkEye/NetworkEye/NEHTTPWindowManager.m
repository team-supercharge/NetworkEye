//
//  NEHTTPWindowManager.m
//  NetworkEye
//
//  Created by Gergo Nemeth on 2017. 08. 22..
//  Copyright © 2017. coderyi. All rights reserved.
//

#import "NEHTTPWindowManager.h"

@interface NEHTTPWindowManager()

@property (nonatomic, strong) UIWindow *window;

@end

@implementation NEHTTPWindowManager

#pragma mark - Singleton
+ (instancetype)sharedManager {
    static NEHTTPWindowManager *sharedMyManager = nil;
    @synchronized(self) {
        if (sharedMyManager == nil)
            sharedMyManager = [[self alloc] init];
    }
    return sharedMyManager;
}

#pragma mark - Display / Dismiss
- (UIViewController *)presentWindowInLevel:(UIWindowLevel)level {
    if (_window != nil) {
        return nil;
    }
    
    UIViewController *viewController = [UIViewController new];
    viewController.view.frame = [UIScreen mainScreen].bounds;
    viewController.view.backgroundColor = [UIColor clearColor];
    
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.hidden = NO;
    self.window.windowLevel = level;
    self.window.rootViewController = viewController;
    [self.window makeKeyAndVisible];
    
    return viewController;
}

- (void)dismissWindow {
    self.window = nil;
}

@end
