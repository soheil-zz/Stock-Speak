//
//  NSData+Hex.m
//  IdeaScale
//
//  Created by Jeremy Przasnyski on 2/24/10.
//  Copyright 2010 Cavoort, LLC. All rights reserved.
//

#import "NSData+Hex.h"

@implementation NSData (Hex)
- (NSString*) hexString {
	NSMutableString *stringBuffer = [NSMutableString
									 stringWithCapacity:([self length] * 2)];
	const unsigned char *dataBuffer = [self bytes];
	int i;
	
	for (i = 0; i < [self length]; ++i)
		[stringBuffer appendFormat:@"%02x", (unsigned long)dataBuffer[ i ]];
	
	return [[stringBuffer copy] autorelease];
}
@end
