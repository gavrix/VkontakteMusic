//
//  SearchWindowController.h
//  Radio
//
//  Created by Gavrix on 9/10/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "VkontakteController.h"

@interface SearchWindowController : NSWindowController <NSTableViewDataSource, NSTableViewDelegate> {

	IBOutlet NSTextField* _statusLabel;
	IBOutlet NSButton*		_searchButton;
	IBOutlet NSTextField*	_searchTextField;
	
	IBOutlet NSTableView*	_tableView;
	
	VkontakteController* _vkontakteController;
	
	
	NSMutableArray* _rows;
	
	
	NSString* filesLocationPath;
}

-(void) setVkontakteController:(VkontakteController*) vkontakteController;
-(IBAction) onButtonSearchPressed:(id) sender;

-(IBAction) onButtonDownloadPressed:(id) sender;
@end
