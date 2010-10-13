//
//  VKontakteSession.h
//  Radio
//
//  Created by Gavrix on 8/6/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface VKontakteSession : NSObject 
{
	NSDate*		_expire;
	NSString*	_mid;
	NSString*	_secret;
	NSString*	_sid;
}

-(id) initWithUserId:(NSString*)mid secret:(NSString*)secret sessinoId:(NSString*)sid expireDate:(NSDate*) expire;

@property (readonly) NSString* userId;
@property (readonly) NSString* secret;
@property (readonly) NSString* sessionId;

@end
