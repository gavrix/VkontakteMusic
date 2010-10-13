//
//  VkontakteController.h
//  Radio
//
//  Created by Gavrix on 8/5/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString* const VkontakteLoginSuccessedNotification;
extern NSString* const VkontakteLoginFailedNotification;
extern NSString* const VkontakteSearchPartiallyCompleteNotification;
extern NSString* const VkontakteSearchCompleteNotification;

// song donwload notifications
extern NSString* const VkontakteSongDownloadStartedNotification;
extern NSString* const VkontakteSongDownloadFailedNotification;
extern NSString* const VkontakteSongDownloadProgressNotification;
extern NSString* const VkontakteSongDownloadFinishedNotification;


extern NSString* const VkontakteSearchPartiallyCompleteResultArrKey;
extern NSString* const VkontakteSearchPartiallyCompleteQueryKey;

extern NSString* const VkontakteSongKey;
extern NSString* const VkontakteDownloadProgressKey;


@class VkontakteSong;


typedef enum
{
	EVkontakteControllerStateNone,
	EVkontakteControllerStateLogin,
	EVkontakteControllerStateAudioSearch,
	EVkontakteControllerStateAudioGet
} EVkontakteControllerState;

@interface VkontakteController : NSObject
{
	BOOL isSendingFirstLoginRequest;
	
	
	NSString* sid;
	NSString* secret;
	NSString* mid;

	EVkontakteControllerState _state;
	NSMutableData*			_responseBuffer;
	
	
	NSMutableDictionary* pendingRequests;
	NSMutableArray* pendingConnections;
	NSMutableArray* pendingUrls;
	
	
	NSMutableArray* pendingDownloads;
	
	NSString* downloadPath;
}

-(id) init;

-(void) login;

-(void) getAudiosForUser:(NSString*) uid;

-(void) getAudiosForUser:(NSString*) uid forAids:(NSArray*) aids;

-(void) getAudiosForGroup:(NSString*) gid;

-(void) getAudiosForGroup:(NSString*) gid forAids:(NSArray*) aids;


#pragma mark -
#pragma mark Searching
-(void) searchAudio:(NSString*) searchString;

#pragma mark -
#pragma mark Downloading
-(void) downloadSong:(VkontakteSong*) song;

-(void) setDownloadLocation:(NSString*) path;
@end
