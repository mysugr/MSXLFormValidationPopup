//
//  MSXLFormAppDelegate.m
//  MSXLFormValidationPopup
//
//  Created by Bernhard Schandl on 09/30/2016.
//  Copyright (c) 2016 Bernhard Schandl. All rights reserved.
//

#import "MSXLFormAppDelegate.h"
#import "MSXLFormViewController.h"


@implementation MSXLFormAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    
    MSXLFormViewController* viewController = [[MSXLFormViewController alloc] init];
    UINavigationController* nc = [[UINavigationController alloc] initWithRootViewController:viewController];
    nc.navigationBar.tintColor = [UIColor whiteColor];
    nc.navigationBar.barStyle = UIBarStyleBlack;
    self.window.rootViewController = nc;
    
    [self.window makeKeyAndVisible];

    return YES;
}

@end
