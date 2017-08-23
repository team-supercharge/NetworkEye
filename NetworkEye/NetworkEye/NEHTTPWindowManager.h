//
//  NEHTTPWindowManager.h
//  NetworkEye
//
//  Created by Gergo Nemeth on 2017. 08. 22..
//  Copyright © 2017. coderyi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface NEHTTPWindowManager : NSObject

// Singleton
+ (instancetype)sharedManager;

#pragma mark - Display / Dismiss
- (UIViewController *)presentWindowInLevel:(UIWindowLevel)level;
- (void)dismissWindow;

@end
