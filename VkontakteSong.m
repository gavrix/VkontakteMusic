//
//  VkontakteSong.m
//  Radio
//
//  Created by Gavrix on 9/29/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "VkontakteSong.h"

@interface  VkontakteSong(Private)
-(NSUInteger) privateAid;
-(NSString*) privateUrl;
@end

@implementation VkontakteSong(Private)
-(NSUInteger) privateAid
{
	return aid;
}

-(NSString*) privateUrl
{
	return url;
}
@end


@implementation VkontakteSong


@synthesize audioId = aid;
@synthesize ownderId = owner_id;
@synthesize artist = artist;
@synthesize title = title;
@synthesize duration = duration;


-(id) initWithDictionary:(NSDictionary*) params
{
	if(![[params allKeys] containsObject:@"aid"] ||
	   ![[params allKeys] containsObject:@"duration"] ||
	   ![[params allKeys] containsObject:@"url"])
		return nil;
	   
	if(nil != (self = [super init]))
	{
		aid = [((NSString*)[params objectForKey:@"aid"]) longLongValue];
		owner_id = [((NSString*)[params objectForKey:@"ownder_id"]) intValue];
		artist = [[params objectForKey:@"artist"] retain];
		title = [[params objectForKey:@"title"] retain];
		duration = [((NSString*)[params objectForKey:@"duration"]) intValue];
		url = [[params objectForKey:@"url"] retain];
		lyrics_id = [((NSString*)[params objectForKey:@"lyrics_id"]) longLongValue];
		
		privateParams = [[NSMutableDictionary alloc] init];
	}

	return self;
}

-(void) dealloc
{
	[artist release];
	[title release];
	[url release];
	[privateParams release];
	
	
	[super dealloc];
}

-(BOOL) isEqual:(id)object
{
	if([object isKindOfClass: [VkontakteSong class]])
	{
	
		VkontakteSong* otherSong = (VkontakteSong*)object;
		
		if(aid == [otherSong privateAid] || [url isEqualToString:[otherSong privateUrl]])
			return YES;
		
		if([self hash] == [otherSong hash])
			return YES;
	}
	return NO;
}
		   
-(NSUInteger) hash
{
	return [[NSString stringWithFormat:@"%@%@%d", artist, title, duration] hash];
}


-(NSString*) stringDuration
{
	return [NSString stringWithFormat:@"%d:%.2d", duration/60, duration%60];
}

-(NSURL*) url
{
	return [NSURL URLWithString:url];
}
@end
