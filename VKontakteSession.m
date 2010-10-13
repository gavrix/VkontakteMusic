//
//  VKontakteSession.m
//  Radio
//
//  Created by Gavrix on 8/6/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "VKontakteSession.h"


@implementation VKontakteSession
-(id) initWithUserId:(NSString*)mid secret:(NSString*)secret sessinoId:(NSString*)sid expireDate:(NSDate*) expire
{
	if(nil!= (self = [super init]))
	{
		_expire = [expire retain];
		_mid = [mid retain];
		_secret = [secret retain];
		_sid = [sid retain];
	}
	
	return self;
}

-(void) dealloc
{
	[_expire release];
	[_mid release];
	[_secret release];
	[_sid release];
	
	[super dealloc];
}

-(NSString*) userId
{
	return _mid;
}
-(NSString *) secret
{
	return _secret;
}
-(NSString *) sessionId
{
	return _sid;
}
@end
