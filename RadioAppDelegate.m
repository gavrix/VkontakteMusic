//
//  RadioAppDelegate.m
//  Radio
//
//  Created by Gavrix on 8/4/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
// dummy comment
// another dummy comment
//

#import "RadioAppDelegate.h"
#import "SearchWindowController.h"

@implementation RadioAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification 
{
	// Insert code here to initialize your application 
	
	vkontakteController = [[VkontakteController alloc] init];
	
	SearchWindowController* searchWinControlelr = [[SearchWindowController alloc] initWithWindowNibName:@"MainWindow"];
	[searchWinControlelr setVkontakteController:vkontakteController];
	[vkontakteController login];
	
	
	[searchWinControlelr showWindow:self];
	[searchWinControlelr release];
}


-(void) applicationWillTerminate:(NSNotification *)notification
{
	[vkontakteController release];
}
@end
