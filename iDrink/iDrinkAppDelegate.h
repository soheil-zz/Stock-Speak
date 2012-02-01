//
//  iDrinkAppDelegate.h
//  iDrink
//
//  Created by sman on 7/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class iDrinkViewController;

@interface iDrinkAppDelegate : NSObject <UIApplicationDelegate> {

}

@property (nonatomic, retain) IBOutlet UIWindow *window;

@property (nonatomic, retain) IBOutlet iDrinkViewController *viewController;


- (NSDictionary *)parseQueryString:(NSString *)query;


@end
