//
//  VkontakteLoginCotroller.m
//  Radio
//
//  Created by Gavrix on 8/6/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "VkontakteLoginCotroller.h"


@implementation VkontakteLoginCotroller

@synthesize loginUrl = _urlToLoad;

-(void) windowDidLoad
{
	[_webView takeStringURLFrom:self];
}

-(NSString*) stringValue
{
	return _urlToLoad;
}

- (NSURLRequest *)webView:(WebView *)sender resource:(id)identifier 
		  willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse 
		   fromDataSource:(WebDataSource *)dataSource
{
	NSString* absoluteString = [[request URL] absoluteString] ;
	
	if([absoluteString rangeOfString:@"login_success"].location != NSNotFound)
	{
		[self.window performClose:self];
		[self autorelease];
	}
	
	return request;
	
}
@end
