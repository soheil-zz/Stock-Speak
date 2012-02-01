//
//  iDrinkAppDelegate.m
//  iDrink
//
//  Created by sman on 7/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "iDrinkAppDelegate.h"
#import "iDrinkViewController.h"
#import "Appirater.h"

@implementation iDrinkAppDelegate


@synthesize window=_window;

@synthesize viewController=_viewController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
     
    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
    
    // ideascale
//    [ISFeedback initSharedInstance:@"559ecd62-4933-4bbb-8b9b-c887652f1ad6"];
    
    // app rater, asks users to leave feedback
    [Appirater appLaunched:YES];
    
    return YES;
}
/*
- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
    if (!url) {  return NO; }
    
    NSString *URLString = [url absoluteString];
    [[NSUserDefaults standardUserDefaults] setObject:URLString forKey:@"url"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    return YES;
}
*/
- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
    
    if (!url) {  return NO; }
    
    NSLog(@"url recieved: %@", url);
    NSLog(@"query string: %@", [url query]);
    NSLog(@"host: %@", [url host]);
    NSLog(@"url path: %@", [url path]);
    //NSDictionary *dict = [self parseQueryString:[url query]];
    //NSLog(@"query dict: %@", dict);
    
    
    //[[NSUserDefaults standardUserDefaults] setObject:[url path] forKey:@"url"];
    //[[NSUserDefaults standardUserDefaults] synchronize];
    
    
    //NSString *url = [[NSUserDefaults standardUserDefaults] stringForKey:@"url"];
    
    //if (url) {
    
    NSString *keyword = [url path];
    self.viewController.topField.text = [keyword substringWithRange:NSMakeRange(1, keyword.length - 1)];
    [self.viewController makeRequestAndGetResults:FALSE];
    //}
    
    
    return YES;
}

- (NSDictionary *)parseQueryString:(NSString *)query {
    NSMutableDictionary *dict = [[[NSMutableDictionary alloc] initWithCapacity:6] autorelease];
    NSArray *pairs = [query componentsSeparatedByString:@"&"];
    
    for (NSString *pair in pairs) {
        NSArray *elements = [pair componentsSeparatedByString:@"="];
        NSString *key = [[elements objectAtIndex:0] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString *val = [[elements objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        [dict setObject:val forKey:key];
    }
    return dict;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
    [Appirater appEnteredForeground:YES];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
    if ([self.viewController.topField.text isEqualToString: @"Please try again"]) {
        self.viewController.topField.text = @"Speak a Stock Name";
    }
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
}

- (void)dealloc
{
    [_window release];
    [_viewController release];
    [super dealloc];
}

@end
