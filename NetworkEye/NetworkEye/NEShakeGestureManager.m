//
//  NEShakeGestureManager.m
//  NetworkEye
//
//  Created by coderyi on 15/11/5.
//  Copyright © 2015年 coderyi. All rights reserved.
//

#import "NEShakeGestureManager.h"

#import <UIKit/UIKit.h>
#import "NEHTTPEyeViewController.h"
#import "NEHTTPWindowManager.h"
#import "NEHTTPModelManager.h"
#import "HAR.h"

@interface NEShakeGestureManager ()<UIAlertViewDelegate>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
@property (nonatomic, strong) UIAlertView *alertView;
#pragma clang diagnostic pop

@end

@implementation NEShakeGestureManager

+ (NEShakeGestureManager *)defaultManager {
    
    static NEShakeGestureManager *staticManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        staticManager=[[NEShakeGestureManager alloc] init];
    });
    return staticManager;
    
}

- (void)showAlertView {
    
    [self.alertView show];
    
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
- (UIAlertView *)alertView {
    
    if (_alertView == nil) {
        _alertView = [[UIAlertView alloc] init];
        _alertView.delegate = self;
		_alertView.title = @"Network Eye";
		[_alertView addButtonWithTitle:@"Clear NetworkEye Cache"];
		[_alertView addButtonWithTitle:@"Export Network Log"];
		[_alertView addButtonWithTitle:@"Go NetworkEye"];
        [_alertView addButtonWithTitle:@"Cancel"];
        [_alertView setCancelButtonIndex:[_alertView numberOfButtons]-1];
    }
    return _alertView;
    
}
#pragma clang diagnostic pop


- (void)presentInformationViewController {
    
    NEHTTPEyeViewController *viewController = [[NEHTTPEyeViewController alloc] init];
    UIViewController *windowViewController = [[NEHTTPWindowManager sharedManager] presentWindowInLevel:UIWindowLevelNormal];
    [windowViewController presentViewController:viewController animated:YES completion:nil];
    
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    
	NSString *buttonTitle = [alertView buttonTitleAtIndex:buttonIndex];
	if ([buttonTitle isEqualToString:@"Clear NetworkEye Cache"]) {
		[self clearCache];
	}
	if ([buttonTitle isEqualToString:@"Export Network Log"]) {
		[self exportLogs];
	}
	if ([buttonTitle isEqualToString:@"Go NetworkEye"]) {
		[self presentInformationViewController];
	}
}

#pragma mark - Clear Cache

- (void)clearCache {
    [[NEHTTPModelManager defaultManager] removeAllMapObjects];
    [[NEHTTPModelManager defaultManager] deleteAllItem];
}

#pragma mark - Export

- (void)exportLogs {
	NSArray *httpRequests=[[[[NEHTTPModelManager defaultManager] allobjects] reverseObjectEnumerator] allObjects];
	if (httpRequests.count < 1) {
		return;
	}
	
	NSURL *filePathURL = [HAR generateWithModelObjects:httpRequests];
	if (filePathURL) {
		UIViewController *windowViewController = [[NEHTTPWindowManager sharedManager] presentWindowInLevel:UIWindowLevelNormal];
		
		UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[filePathURL]
																							 applicationActivities:nil];
		activityViewController.completionHandler = ^(UIActivityType activityType, BOOL completed) {
			[[NEHTTPWindowManager sharedManager] dismissWindow];
		};
		
		[windowViewController presentViewController:activityViewController
										   animated:YES
										 completion:nil];
	}
}

@end
