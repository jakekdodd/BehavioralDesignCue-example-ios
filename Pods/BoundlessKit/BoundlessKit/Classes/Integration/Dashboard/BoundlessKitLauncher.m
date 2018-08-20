//
//  BoundlessKitLauncher.m
//  Pods
//
//  Created by Akash Desai on 6/16/17.
//
//

#import <BoundlessKit/BoundlessKit-Swift.h>

@implementation UIApplication (BoundlessKitApplicationLauncher)

+ (void) load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [[BoundlessKitApplicationLauncherBridge standard] appDidLaunch: [[NSNotification alloc] initWithName:@"" object:nil userInfo:nil]];
    });
}

@end

