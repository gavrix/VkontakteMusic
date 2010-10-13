//
//  VkontakteSong.h
//  Radio
//
//  Created by Gavrix on 9/29/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface VkontakteSong : NSObject 
{
	NSUInteger	aid;
	NSUInteger	owner_id;
	NSString*	artist;
	NSString*	title;
	NSUInteger	duration;
	NSString*	url;
	NSUInteger	lyrics_id;
	
	NSMutableDictionary* privateParams;
	
}

@property(readonly, nonatomic) NSUInteger audioId;
@property(readonly, nonatomic) NSUInteger ownderId;
@property(readonly, nonatomic) NSString* artist;
@property(readonly, nonatomic) NSString* title;
@property(readonly, nonatomic) NSUInteger duration;
@property(readonly, getter = url) NSURL* url;
@property(readonly, getter = stringDuration)   NSString* stringDuration;


-(id) initWithDictionary:(NSDictionary*) params;
@end
