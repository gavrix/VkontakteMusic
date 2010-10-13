//
//  SearchWindowController.m
//  Radio
//
//  Created by Gavrix on 9/10/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "SearchWindowController.h"
#import "VkontakteSong.h"
#import "ProgressButtonTableViewCell.h"

@interface VkontakteSong(DonwloadStatus)
@property BOOL complete;
@property NSInteger progress;
@end

@interface SearchWindowController()

-(BOOL) isSongDownloaded:(VkontakteSong*) song;
@end

@implementation VkontakteSong(DonwloadStatus)

-(BOOL) complete
{
	
	@synchronized(privateParams)
	{
		if([[privateParams allKeys] containsObject:@"complete"])
		   return [(NSNumber*)[privateParams objectForKey:@"complete"] boolValue];
	}
   return NO;
}

- (void) setComplete:(BOOL) complete
{
	@synchronized(privateParams)
	{
		[privateParams setObject:[NSNumber numberWithBool:complete] forKey:@"complete"];
	}
}

-(NSInteger) progress
{
	@synchronized(privateParams)
	{
		if([[privateParams allKeys] containsObject:@"progress"])
			return [(NSNumber*)[privateParams objectForKey:@"progress"] integerValue];
	}
	return NSNotFound;
}

-(void) setProgress:(NSInteger) progress
{
	@synchronized(privateParams)
	{
		[privateParams setObject:[NSNumber numberWithInteger:progress] forKey:@"progress"];
	}
}
@end



@implementation SearchWindowController

-(void) windowDidLoad
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(vkontakteControllerLoginSuccessed:) 
												 name:VkontakteLoginSuccessedNotification object:nil];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(vkontakteControllerLoginFailed:) 
												 name:VkontakteLoginFailedNotification object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(vkontakteControllerSearchFinished:) 
												 name:VkontakteSearchPartiallyCompleteNotification object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(vkontakteControllerSearchFinished:) 
												 name:VkontakteSongDownloadStartedNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(vkontakteSongDownloadProgress:) 
												 name:VkontakteSongDownloadProgressNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(vkontakteSongDownloadFinished:) 
												 name:VkontakteSongDownloadFinishedNotification object:nil];
	
	
	filesLocationPath = [[[NSBundle mainBundle] bundlePath] retain];
}


-(void) vkontakteControllerLoginSuccessed:(NSNotification*) notification
{
	[_statusLabel setStringValue:@"logged in"];
	[_searchButton setEnabled:YES];
}


-(void) vkontakteControllerLoginFailed:(NSNotification*) notification
{
	[_statusLabel setStringValue:@"log in failed"];
}

-(void) vkontakteSongDownloadStarted:(NSNotification*) notification
{
	VkontakteSong* song = [[notification userInfo] objectForKey:VkontakteSongKey];
	song.progress = 0;
	NSInteger row = [_rows indexOfObject:song];
	
	[_tableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:row] columnIndexes:[NSIndexSet indexSetWithIndex:5]];
}

-(void) vkontakteSongDownloadFinished:(NSNotification*) notification
{
	VkontakteSong* song = [[notification userInfo] objectForKey:VkontakteSongKey];
	song.complete = YES;
	NSInteger row = [_rows indexOfObject:song];
	
	[_tableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:row] columnIndexes:[NSIndexSet indexSetWithIndex:5]];
}


-(void) vkontakteSongDownloadProgress:(NSNotification*) notification
{
	VkontakteSong* song = [[notification userInfo] objectForKey:VkontakteSongKey];
	
	song.progress = [(NSNumber*)[[notification userInfo] objectForKey:VkontakteDownloadProgressKey] integerValue];
	
	NSInteger row = [_rows indexOfObject:song];
	
	
	[_tableView setNeedsDisplayInRect:[_tableView frameOfCellAtColumn:5 row:row]];
	
}

-(void) vkontakteControllerSearchFinished:(NSNotification*) notification
{
	NSArray* result = [[notification userInfo] objectForKey:VkontakteSearchPartiallyCompleteResultArrKey];
	if(result != nil)
	{
		if(_rows == nil )
			_rows = [[NSMutableArray alloc] init];
		
		for(VkontakteSong* song in result)
		{
			[song setComplete:[self isSongDownloaded:song]];
		}
			
		
		[_rows addObjectsFromArray:result];
		
		
		[_statusLabel setIntValue:[_rows count]];
		[_tableView reloadData];
	}
		
}



-(IBAction) onButtonSearchPressed:(id) sender
{
	[_vkontakteController searchAudio:[_searchTextField stringValue]];
}


-(IBAction) onButtonDownloadPressed:(id) sender
{
	NSInteger row = [_tableView clickedRow];
	VkontakteSong* song = [_rows objectAtIndex:row];
	
	[_vkontakteController downloadSong:song];
	
}


-(void) setVkontakteController:(VkontakteController*) vkontakteController
{
	[_vkontakteController release];
	_vkontakteController = [vkontakteController retain];
	
	[_vkontakteController setDownloadLocation: filesLocationPath];
}


-(void) dealloc
{
	[_vkontakteController release];
	[filesLocationPath release];
	[super dealloc];
}


#pragma mark -
#pragma mark  utilities methods
-(BOOL) isSongDownloaded:(VkontakteSong*) song
{
	NSString* path = [song.url absoluteString];
	NSArray* components = [path componentsSeparatedByString:@"/"];
	NSString* fileName = (NSString*)[components objectAtIndex:[components count]-1];
	
	NSString* filePath = [filesLocationPath stringByAppendingPathComponent:fileName];
	
	return [[NSFileManager defaultManager] fileExistsAtPath:filePath];
	
}

#pragma mark -
#pragma mark NSTableViewDataSource
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return [_rows count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	VkontakteSong* song = [_rows objectAtIndex:row];
	
	if([[[tableColumn headerCell] stringValue] isEqualToString:@"ID"])
	{
		return  [NSString stringWithFormat:@"%d", song.audioId];
	}
	else if([[[tableColumn headerCell] stringValue] isEqualToString:@"Artist"])
	{
		return song.artist;	
	}
	else if([[[tableColumn headerCell] stringValue] isEqualToString:@"Title"])
	{
		return song.title;
	}
	else if([[[tableColumn headerCell] stringValue] isEqualToString:@"Duration"])
	{
		return song.stringDuration;
	}
	else if([[[tableColumn headerCell] stringValue] isEqualToString:@"Url"])
	{
		return [song.url description];
	}
	else if([[[tableColumn headerCell] stringValue] isEqualToString:@"Status"])
	{
		if(song.complete)
			return @"Complete";
		else
			return [NSNumber numberWithFloat:song.progress];
	}

	
	return nil;
	 
}

-(void) tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	
}

- (NSCell *)tableView:(NSTableView *)tableView dataCellForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	if([[[tableColumn headerCell] stringValue] isEqualToString:@"Status"])
	{
		VkontakteSong* song = [_rows objectAtIndex:row];
		if(song.progress == NSNotFound && !song.complete)
		{
			
			NSButtonCell* b = [[NSButtonCell alloc]init];
			[b setButtonType:NSMomentaryPushInButton];
			[b setBezeled:YES];
			[b setBezelStyle:NSRoundedBezelStyle];
			[b setTitle:@"Download1"];
			[b setFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];
			[b setControlSize:NSMiniControlSize];
			
			
			[b setTarget:self];
			[b setAction:@selector(onButtonDownloadPressed:)];
			return [b autorelease]; 
		}
		else if(song.complete)
		{
			NSTextFieldCell* c = [[NSTextFieldCell alloc] initTextCell:@"Complete"];
			return [c autorelease];
		}
		else 
		{
			NSLevelIndicatorCell* c = [[NSLevelIndicatorCell alloc] initWithLevelIndicatorStyle:NSContinuousCapacityLevelIndicatorStyle];
			[c setEnabled:YES];
			[c setMinValue:0];
			[c setMaxValue:100];
			
			NSLog(@"downloading song, progress = %f", song.progress/100.0);
			
			return [c autorelease];
		}

	}

	return [tableColumn dataCell];

}


- (BOOL)tableView:(NSTableView *)aTableView shouldSelectTableColumn:(NSTableColumn *)aTableColumn
{
	return NO;
}
@end
