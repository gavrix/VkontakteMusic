//
//  VkontakteLoginCotroller.h
//  Radio
//
//  Created by Gavrix on 8/6/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@interface VkontakteLoginCotroller : NSWindowController 
{
	IBOutlet WebView* _webView;
	NSString* _urlToLoad;
}

@property(nonatomic, retain) NSString* loginUrl;
@end
