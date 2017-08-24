//
//  UIWindow+NEExtension.m
//  NetworkEye
//
//  Created by coderyi on 15/11/14.
//  Copyright © 2015年 coderyi. All rights reserved.
//

#import "UIWindow+NEExtension.h"
#import "NEShakeGestureManager.h"
#import "NEHTTPEye.h"

@implementation UIWindow (NEExtension)

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
	if (![NEHTTPEye isEnabled]) {
		return;
	}
	
    if (event.type == UIEventTypeMotion && event.subtype == UIEventSubtypeMotionShake) {
        [[NEShakeGestureManager defaultManager] showAlertView];
    }
  
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	if (![NEHTTPEye isEnabled]) {
		return;
	}
 
    int twoFingerTag=NO;
    if ([event allTouches].count==2) {
        for (UITouch *touch in [event allTouches]) {
            if (touch.tapCount==1) {
                twoFingerTag=YES;
            }else{
                twoFingerTag=NO;
            }
        }
    }
    if (twoFingerTag) {
        [[NEShakeGestureManager defaultManager] showAlertView];
    }
  
}

@end
