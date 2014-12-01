//
//  Copyright (C) 2007-2009 Atsunori Saito <sai@yedo.com>.
//  All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

#import <objc/runtime.h>

@interface NSApplication (Replace)
- (void)replace_sendEvent: (NSEvent*)event;
@end

@implementation NSApplication (Replace)

- (void)sendSwapEvent: (NSEvent*)event modifierFlags:(NSUInteger)flags
{
	NSEvent* newevent =
		[NSEvent keyEventWithType: [event type]
						 location: [event locationInWindow]
					modifierFlags: flags
						timestamp: [event timestamp]
					 windowNumber: [event windowNumber]
						  context: [event context]
					   characters: [event charactersIgnoringModifiers]
	  charactersIgnoringModifiers: [event charactersIgnoringModifiers]
						isARepeat: [event isARepeat]
						  keyCode: [event keyCode]];
	[self replace_sendEvent: newevent];
}

- (void)replace_sendEvent: (NSEvent*)event
{
	NSEventType type = [event type];
	if (type == NSKeyDown || type == NSKeyUp) {
		NSUInteger flags = [event modifierFlags];
		if ((flags & (NSAlternateKeyMask | NSCommandKeyMask)) ==
			NSCommandKeyMask) {
#ifndef REPLACE_ALL_KEYS
			if ([event keyCode] == 49) {
				/* command+space */
				[self replace_sendEvent: event];
				return;
			}
#endif
			flags &= ~NSCommandKeyMask;
			flags |= NSAlternateKeyMask;
			[self sendSwapEvent: event modifierFlags: flags];
			return;
		}
		if ((flags & (NSAlternateKeyMask | NSCommandKeyMask)) ==
			NSAlternateKeyMask) {
			NSUInteger flags = [event modifierFlags];
			flags &= ~NSAlternateKeyMask;
			flags |= NSCommandKeyMask;
			[self sendSwapEvent: event modifierFlags: flags];
			return;
		}
	}
	[self replace_sendEvent: event];
}

@end

@interface SOCPlugin : NSObject
@end

@implementation SOCPlugin

+ (SOCPlugin*)sharedInstance
{
	static SOCPlugin* plugin = nil;
	if (plugin == nil) plugin = [[SOCPlugin alloc] init];
	return plugin;
}

+ (void)load
{
	Method org = class_getInstanceMethod([NSApplication class],
										 @selector(sendEvent:));
	Method new = class_getInstanceMethod([NSApplication class],
										 @selector(replace_sendEvent:));
	method_exchangeImplementations(org, new);
	SOCPlugin* plugin = [SOCPlugin sharedInstance];
	NSLog(@"SwapOptCmd installed");
}

@end
