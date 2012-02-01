//
//  NSHTTPURLResponse+StatusCodes.m
//  IdeaScale
//
//  Created by Jeremy Przasnyski on 11/11/09.
//  Copyright 2009 Cavoort, LLC. All rights reserved.
//
#import "NSHTTPURLResponse+StatusCodes.h"

@implementation NSHTTPURLResponse (StatusCodes)
-(BOOL)is200OK {
	return [self statusCode] == 200;
}
-(BOOL)isOK {
	return 200 <= [self statusCode] && [self statusCode] <= 299;
}
-(BOOL)isRedirect {
	return 300 <= [self statusCode] && [self statusCode] <= 399;
}
-(BOOL)isClientError {
	return 400 <= [self statusCode] && [self statusCode] <= 499;
}
-(BOOL)isServerError {
	return 500 <= [self statusCode] && [self statusCode] <= 599;
}
@end
