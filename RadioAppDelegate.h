//
//  RadioAppDelegate.h
//  Radio
//
//  Created by Gavrix on 8/4/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "VkontakteController.h"


@interface RadioAppDelegate : NSObject <NSApplicationDelegate> 
{
	VkontakteController* vkontakteController;
	
}

@property (assign) IBOutlet NSWindow *window;

@end
