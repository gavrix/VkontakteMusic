//
//  VkontakteController.m
//  Radio
//
//  Created by Gavrix on 8/5/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "VkontakteController.h"
#import "VkontakteLoginCotroller.h"
#import "JSON.h"
#import <openssl/md5.h>
#import "VkontakteSong.h"

#define APP_ID 1948338

NSString* const VkontakteLoginSuccessedNotification = @"VkontakteLoginSuccessed";
NSString* const VkontakteLoginFailedNotification = @"VkontakteLoginFailed";
NSString* const VkontakteSearchPartiallyCompleteNotification = @"VkontakteSearchPartiallyComplete";
NSString* const VkontakteSearchCompleteNotification = @"VkontakteSearchComplete";

//song download notifications
NSString* const VkontakteSongDownloadStartedNotification = @"VkontakteSongDownloadStarted";
NSString* const VkontakteSongDownloadFailedNotification = @"VkontakteSongDownloadFailed";
NSString* const VkontakteSongDownloadProgressNotification = @"VkontakteSongDownloadProgress";
NSString* const VkontakteSongDownloadFinishedNotification = @"VkontakteSongDownloadFinished";


NSString* const VkontakteSearchPartiallyCompleteResultArrKey = @"VkontakteSearchPartiallyCompleteResultArrKey";
NSString* const VkontakteSearchPartiallyCompleteQueryKey = @"VkontakteSearchPartiallyCompleteQueryKey";

NSString* const VkontakteSongKey = @"VkontakteSongKey";
NSString* const VkontakteDownloadProgressKey = @"VkontakteDownloadProgressKey";


@interface VkontakteController(Private)
-(void) loggedIn:(NSDictionary*) params;
-(NSString*) makeSignature:(NSDictionary*) params;
-(NSString*) makeQueryString:(NSDictionary*) params;
@end


@implementation VkontakteController
typedef enum
{
	EVkontakteAccessAllowNotifications =1,
	EVkontakteAccessFriends = 2,
	EVkontakteAccessPhotos = 4,	
	EVkontakteAccessAudio = 8,	
	EVkontakteAccessVideo = 16,	
	EVkontakteAccessOffers = 32,	
	EVkontakteAccessQuestions = 64,	
	EVkontakteAccessWikiPages = 128,	
	EVkontakteAccessStatuses = 1024,	
	EVkontakteAccessNotes = 2048,	
	EVkontakteAccessMessages = 4096,	
	EVkontakteAccessWall = 8192
} EVkontakteAccess;

typedef enum
{
	EVkontakteAudioSortDate=0,
	EVkontakteAudioSortDuration
} EVkontakteAudioSort;




-(void) login;
{
	NSInteger rightsMask = EVkontakteAccessAudio;
	NSString* urlString = [NSString stringWithFormat:@"http://vkontakte.ru/login.php?"
						   "app=%d&layout=popup&type=browser&settings=%d", APP_ID, rightsMask];
	
	NSURLRequest* request = [NSURLRequest requestWithURL: [NSURL URLWithString:urlString]];
	
	[NSURLConnection connectionWithRequest:request delegate:self];
	_state = EVkontakteControllerStateLogin;
}

-(id) init
{
	if(nil != (self = [super init]))
	{
		pendingRequests = [[NSMutableDictionary alloc] init];
		pendingConnections = [[NSMutableArray alloc] init];
		pendingUrls = [[NSMutableArray alloc] init];
	}
	return self;
}


-(void) dealloc
{
	[pendingRequests release];
	[pendingConnections release];
	[pendingUrls release];
	
	[pendingDownloads release];
	
	[super dealloc];
}
#pragma mark -
#pragma mark private utilities
-(NSString*) makeSignature:(NSDictionary*) params
{
	
	
	NSArray* allKeys = [params allKeys];
	NSArray* sortedKeys = [allKeys sortedArrayUsingSelector:@selector(compare:)];
	
	NSMutableString* resultStr = [NSMutableString stringWithString:mid];
	
	for(NSInteger i=0; i< [sortedKeys count]; i++)
	{
		NSString* key = [sortedKeys objectAtIndex:i];
		if(![key isEqualToString:@"sid"] && ![key hasPrefix:@"intern_"])
		{
			[resultStr appendFormat:@"%@=%@", key, [params objectForKey:key]];
		}
	}

	[resultStr appendString:secret];
	
	NSData* data = [resultStr dataUsingEncoding:NSUTF8StringEncoding] ;
	unsigned char digest[16];
	MD5([data bytes], [data length], digest);
	NSMutableString* hashStr = [NSMutableString stringWithString:@""];
	for(NSInteger i=0; i<16;i++)
	{
		[hashStr appendFormat:@"%02x", digest[i]];
	}
	
	return [NSString stringWithString:hashStr];
}

-(NSString*) makeQueryString:(NSDictionary*) params
{
	NSMutableString* resultStr = [NSMutableString stringWithString:@""];
	for(NSString* key in [params allKeys])
	{
		if(![key hasPrefix:@"intern_"])
			[resultStr appendFormat:([resultStr length]? @"&%@=%@": @"%@=%@"), key, [params objectForKey:key]];
	}
	
	return [NSString stringWithString:resultStr];
}


-(void) makeRequest:(NSMutableDictionary*) params
{
	[params removeObjectForKey:@"sig"];
	NSString* sig = [self makeSignature:params];
	[params setValue:sig forKey:@"sig"];

	NSString* queryString = [self makeQueryString:params];
	NSString* urlString = [NSString stringWithFormat:@"http://api.vkontakte.ru/api.php?%@", queryString];
	

	NSLog(@"performing request %@", urlString);
	NSURL* url = [NSURL URLWithString:urlString];
	NSURLRequest* request = [NSURLRequest requestWithURL: url];
	NSURLConnection* conneciton = [NSURLConnection connectionWithRequest:request delegate:self];
	[pendingRequests setObject:params forKey:url];
	[pendingConnections addObject:conneciton];
	[pendingUrls addObject:url];
	
}

#pragma mark -
#pragma mark private Vkontakte API methods

-(void) audioGetWithUid:(NSString*) uid withGid:(NSString*)gid withAids:(NSString*) aids
{
	NSMutableDictionary* params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
								   [NSString stringWithFormat:@"%d", APP_ID], @"api_id",
								   @"audio.get", @"method",
								   @"3.0", @"v", 
								   sid, @"sid",
								   @"JSON", @"format",
								   nil];
	if(uid != nil)
		[params setValue:uid forKey:@"uid"];
	if(gid != nil)
		[params setValue:gid forKey:@"gid"];
	
	if(aids != nil)
		[params setValue:aids forKey:@"aids"];
	
	
	_state = EVkontakteControllerStateAudioGet;
	[self makeRequest:params];
}

-(void) audioSearchWithQuery:(NSString*)query sorted:(EVkontakteAudioSort)sort withLyrics:(BOOL) withLyrics
					   count:(NSInteger) count offset:(NSInteger) offset 
{
	if(query == nil)
	{
		NSLog(@"query string is nil, nothing to request");
		return;
	}
	NSMutableDictionary* params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
								   [NSString stringWithFormat:@"%d", APP_ID], @"api_id",
								   @"audio.search", @"method",
								   @"3.0", @"v", 
								   sid, @"sid",
								   query, @"q",
								   [NSString stringWithFormat:@"%d", sort] ,@"sort",
								   withLyrics?@"1":@"0", @"lyrics",
								   [NSString stringWithFormat:@"%d", MIN(200,count)], @"count",
								   [NSString stringWithFormat:@"%d", offset], @"offset",
								   @"JSON", @"format",
								   nil];
		
	_state = EVkontakteControllerStateAudioSearch;
	[self makeRequest:params];
	
}



#pragma mark -
#pragma mark public Vkontakte methods

-(void) getAudiosForUser:(NSString*) uid
{
	[self audioGetWithUid:uid withGid:nil withAids:nil];
}

-(void) getAudiosForUser:(NSString*) uid forAids:(NSArray*) aids
{
	NSMutableString* aidsStr = [[NSMutableString alloc] initWithString:@""];
	for(NSString* aid in aids)
		[aidsStr appendFormat: ( ([aidsStr length] != 0)? @",%@": @"%@"), aid];
	
	[self audioGetWithUid:uid withGid:nil withAids:aidsStr];
	
	[aidsStr release];
}

-(void) getAudiosForGroup:(NSString*) gid
{
	[self audioGetWithUid:nil withGid:gid withAids:nil];
}

-(void) getAudiosForGroup:(NSString*) gid forAids:(NSArray*) aids
{
	NSMutableString* aidsStr = [[NSMutableString alloc] initWithString:@""];
	for(NSString* aid in aids)
		[aidsStr appendFormat: ( ([aidsStr length] != 0)? @",%@": @"%@"), aid];
	
	[self audioGetWithUid:nil withGid:gid withAids:aidsStr];
	
	[aidsStr release];
}

-(void) searchAudio:(NSString*) searchString
{
	[self audioSearchWithQuery:searchString sorted:EVkontakteAudioSortDate 
					withLyrics:NO count:200 offset:0];
}



#pragma mark Downloading
-(void) downloadSong:(VkontakteSong*) song
{
	
	NSURLRequest* request = [NSURLRequest requestWithURL:[song url]];
	
	NSURLDownload* urlDownload = [[NSURLDownload alloc] initWithRequest:request delegate:self];
	
	if(pendingDownloads == nil)
		pendingDownloads = [[NSMutableArray alloc] init];
	
	NSMutableArray* downloadparams = [NSMutableArray arrayWithObjects:urlDownload, song, 
									  [NSNumber numberWithLongLong:0],[NSNumber numberWithLongLong:0], nil];
	[pendingDownloads addObject:downloadparams];
}

-(void) setDownloadLocation:(NSString*) path
{
	downloadPath = path;
}

#pragma mark -

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request 
			redirectResponse:(NSURLResponse *)redirectResponse
{
	NSString* absoluteString = [[request URL] absoluteString];
	NSLog(@"redirecting to url:%@", absoluteString);
	

	[_responseBuffer release];
	_responseBuffer = [[NSMutableData alloc] initWithLength:0];
	
	return request;
}


- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	NSLog(@"did failed loading %@ with error %@", error);
}

-(void) connectionDidFinishLoading:(NSURLConnection *)connection
{
	NSURL* url = nil;
	if([pendingConnections indexOfObject:connection] != NSNotFound)
		url = [pendingUrls objectAtIndex:[pendingConnections indexOfObject:connection]];
	
	switch (_state) 
	{
		case EVkontakteControllerStateLogin:
			_state = EVkontakteControllerStateNone;

			if(sid != nil)
				[[NSNotificationCenter defaultCenter] postNotificationName:VkontakteLoginSuccessedNotification 
															object:nil];
			else 
				[[NSNotificationCenter defaultCenter] postNotificationName:VkontakteLoginFailedNotification 
																	object:nil];
			break;
			
		case EVkontakteControllerStateAudioSearch:
		{
			
			_state = EVkontakteControllerStateNone;

			SBJSON* parser = [[SBJSON alloc] init];
			NSError* error = nil;
			NSString* responseString = [[NSString alloc] initWithBytes:[_responseBuffer bytes] length:[_responseBuffer length]
															  encoding:NSUTF8StringEncoding];
			
			NSDictionary* params = [parser objectWithString:
									responseString allowScalar:YES error:&error];
			[responseString release];
			[parser release];
			
			NSArray* resp = [params objectForKey:@"response"];
			NSArray* recordsArr = [resp objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:(NSRange){1,[resp count]-1}]];
			
			BOOL isLastResponse = ([recordsArr count] < 200);
			
			NSMutableArray* newArr = [[NSMutableArray alloc] init];
			
			
			NSMutableArray* cashedResult = nil;
			
			
			NSMutableDictionary* reqParams = (NSMutableDictionary*)[pendingRequests objectForKey: url];
			if([[reqParams allKeys] containsObject:@"intern_cashedResult"])
			{
				cashedResult = [reqParams objectForKey:@"intern_cashedResult"];
			}
			else 
			{
				cashedResult = [[NSMutableArray alloc] init];
				[reqParams setObject:cashedResult forKey:@"intern_cashedResult"];
				[cashedResult release];
			}
			
			
			
			for(NSDictionary* record in recordsArr)
			{
				VkontakteSong* song = [[VkontakteSong alloc] initWithDictionary:record];
				
				if(!song)
					continue;
				
				if(![cashedResult containsObject:song])
				{
					[newArr addObject:song];
					[cashedResult addObject:song];
				}
				[song release];
				
			}
			
			NSDictionary *notificationUserInfo = [NSDictionary dictionaryWithObjectsAndKeys:
												  newArr, VkontakteSearchPartiallyCompleteResultArrKey,
												  [reqParams objectForKey:@"q"], VkontakteSearchPartiallyCompleteQueryKey, nil];
			[[NSNotificationCenter defaultCenter] postNotificationName:VkontakteSearchPartiallyCompleteNotification
																object:nil 
															  userInfo:notificationUserInfo];
			[newArr release];
			
			if(isLastResponse)
			{
				NSDictionary *notificationUserInfo = [NSDictionary dictionaryWithObjectsAndKeys:
													  [reqParams objectForKey:@"q"], VkontakteSearchPartiallyCompleteQueryKey, nil];
				[[NSNotificationCenter defaultCenter] postNotificationName:VkontakteSearchPartiallyCompleteNotification
																	object:nil 
																  userInfo:notificationUserInfo];		
				
			}
			else 
			{
				NSInteger currentOffset = [(NSString*)[reqParams objectForKey:@"offset"] integerValue];
				currentOffset +=200;
				[reqParams setValue:[NSString stringWithFormat:@"%d", currentOffset] forKey:@"offset"];
				
				_state = EVkontakteControllerStateAudioSearch;
				[self makeRequest:reqParams];
				
			}
			[pendingRequests removeObjectForKey:url];
			
			
		}
			break;
		default:
			break;
	}

	[pendingConnections removeObject:connection];
	[pendingUrls removeObject:url];
	
}
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	NSLog(@"did receive response.");
	
	NSString* absoluteString = [[response URL] absoluteString];
	switch (_state) 
	{
		case EVkontakteControllerStateLogin:
			
			if([absoluteString rangeOfString:@"login_success"].location != NSNotFound)
			{
				//login success
				NSRange sessionStringRange = [absoluteString rangeOfString:@"#session="];
				NSInteger startIndex = sessionStringRange.location + sessionStringRange.length;
				
				
				NSString* jsonString = [[absoluteString substringFromIndex:startIndex] stringByReplacingPercentEscapesUsingEncoding:
										NSUTF8StringEncoding];
				
				SBJSON* parser = [[SBJSON alloc] init];
				
				NSDictionary* params = [parser objectWithString:jsonString];
				[parser release];
				
				[mid release];
				mid =  [[NSString alloc ] initWithFormat:@"%d",  [((NSNumber*)[params objectForKey:@"mid"]) integerValue]] ;
				
				[secret release];
				secret = [[params objectForKey:@"secret"] retain];
				
				[sid release];
				sid = [[params objectForKey:@"sid"] retain];
				
			}
			else if([absoluteString rangeOfString:@"Login failure"].location != NSNotFound)
			{
				//login failed
			}
			else 
			{
				
				VkontakteLoginCotroller* winControlelr = [[VkontakteLoginCotroller alloc] 
														  initWithWindowNibName:@"VkontakteLogin"];
				
				NSInteger rightsMask = EVkontakteAccessAudio;;
				winControlelr.loginUrl = [NSString stringWithFormat:@"http://vkontakte.ru/login.php?"
										  "app=%d&layout=popup&type=browser&settings=%d", APP_ID, rightsMask];
				(void)winControlelr.window;
				//[winControlelr autorelease];
			}
			break;
			
		default:
			break;
	}
	
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	NSString* str = [[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSUTF8StringEncoding];
	NSLog(@"Data: %@", str);
	[str release];

	switch (_state) 
	{
		case EVkontakteControllerStateAudioSearch:
		{
			[_responseBuffer appendData:data];
		}			
			break;
		default:
			break;
	}
	
	
}


#pragma mark -
#pragma mark NSURLDownload delegate methods
- (void)download:(NSURLDownload *)download didReceiveResponse:(NSURLResponse *)response
{
	for(NSMutableArray* params in pendingDownloads)
	{
		if([params objectAtIndex:0] != download)
			continue;
		
		[params replaceObjectAtIndex:2 withObject:[NSNumber numberWithLongLong:0]];
		[params replaceObjectAtIndex:3 withObject:[NSNumber numberWithLongLong:[response expectedContentLength]]];
		
		NSDictionary *notificationUserInfo = [NSDictionary dictionaryWithObjectsAndKeys:
											  [params objectAtIndex:1], VkontakteSongKey,
											  nil];
		[[NSNotificationCenter defaultCenter] postNotificationName:VkontakteSongDownloadStartedNotification
															object:nil 
														  userInfo:notificationUserInfo];
	}
	
}


- (void)download:(NSURLDownload *)download decideDestinationWithSuggestedFilename:(NSString *)filename
{
	
	NSString *destinationFilename;
	if(downloadPath != nil && [downloadPath length])
	{
		destinationFilename = [downloadPath  stringByAppendingPathComponent:filename];
	}
	else
		destinationFilename = [[[NSBundle mainBundle] bundlePath]  stringByAppendingPathComponent:filename];
	
    [download setDestination:destinationFilename allowOverwrite:YES];
}


- (void)download:(NSURLDownload *)download didFailWithError:(NSError *)error
{
	for(NSArray* downloadParams in pendingDownloads)
	{
		if([downloadParams objectAtIndex:0] != download)
			continue;
		
		NSDictionary *notificationUserInfo = [NSDictionary dictionaryWithObjectsAndKeys:
											  [downloadParams objectAtIndex:1], VkontakteSongKey,
											  nil];
		[[NSNotificationCenter defaultCenter] postNotificationName:VkontakteSongDownloadFailedNotification
															object:nil 
														  userInfo:notificationUserInfo];
		[pendingDownloads removeObject:downloadParams];
		break;
	}
	
    [download release];	
}

- (void)downloadDidFinish:(NSURLDownload *)download
{
	for(NSArray* downloadParams in pendingDownloads)
	{
		if([downloadParams objectAtIndex:0] != download)
			continue;
		
		NSDictionary *notificationUserInfo = [NSDictionary dictionaryWithObjectsAndKeys:
											  [downloadParams objectAtIndex:1], VkontakteSongKey,
											  nil];
		[[NSNotificationCenter defaultCenter] postNotificationName:VkontakteSongDownloadFinishedNotification
															object:nil 
														  userInfo:notificationUserInfo];
		
		
		[pendingDownloads removeObject:downloadParams];
		break;
	}
	
    [download release];	
}

- (void)download:(NSURLDownload *)download didReceiveDataOfLength:(NSUInteger)length
{
	
	for(NSMutableArray* downloadParams in pendingDownloads)
	{
		if([downloadParams objectAtIndex:0] != download)
			continue;
		
		long long expectedLength = [(NSNumber*)[downloadParams objectAtIndex:3] longLongValue];
		long long bytesReceived = [(NSNumber*)[downloadParams objectAtIndex:2] longLongValue];
		bytesReceived += length;
		
		[downloadParams replaceObjectAtIndex:2 withObject:[NSNumber numberWithLongLong:bytesReceived]];
		
		NSDictionary *notificationUserInfo = [NSDictionary dictionaryWithObjectsAndKeys:
											  [downloadParams objectAtIndex:1], VkontakteSongKey,
											  [NSNumber numberWithInt:bytesReceived*100/expectedLength], VkontakteDownloadProgressKey,
											  nil];
		[[NSNotificationCenter defaultCenter] postNotificationName:VkontakteSongDownloadProgressNotification
															object:nil 
														  userInfo:notificationUserInfo];
		
		
	}
}
@end
