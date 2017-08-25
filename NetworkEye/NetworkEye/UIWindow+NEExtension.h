//
//  UIWindow+NEExtension.h
//  NetworkEye
//
//  Created by coderyi on 15/11/14.
//  Copyright © 2015年 coderyi. All rights reserved.
//

// This file is only built into the application if it's a DEBUG build.
// If you want to use it in release builds (eg. you have different scheme
// for test envinronment and you send test builds via Fabric) you can
// copy this file to your project and use a different ifdef (eg. #if !DEBUG && !RELEASE && !MOCK)
#if defined(DEBUG)||defined(_DEBUG)
#import <UIKit/UIKit.h>

@interface UIWindow (NEExtension)

@end
#endif
