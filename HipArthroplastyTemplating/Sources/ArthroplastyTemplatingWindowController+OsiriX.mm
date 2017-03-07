//
//  ArthroplastyTemplatingWindowController+OsiriX.mm
//  HipArthroplastyTemplating
//  Created by Alessandro Volz on 08.09.09.
//  Copyright 2007-2016 OsiriX Team
//  Copyright 2017 volz.io
//

#import "ArthroplastyTemplatingWindowController+OsiriX.h"

@implementation ArthroplastyTemplatingWindowController (OsiriX)

-(void)keyDown:(NSEvent*)event {
	if ([[event characters] isEqualToString:@"+"]) {
		[_sizes selectItemAtIndex:([_sizes indexOfSelectedItem]+1)%[_sizes numberOfItems]];
		[_sizes setNeedsDisplay:YES];
		[self setFamily:_sizes];
	} else
		if ([[event characters] isEqualToString:@"-"]) {
			NSUInteger index = [_sizes indexOfSelectedItem];
			if (index == 0) index = [_sizes numberOfItems]-1;
            else --index;
			[_sizes selectItemAtIndex:index];
			[_sizes setNeedsDisplay:YES];
			[self setFamily:_sizes];
		} else
			[super keyDown:event];
}

@end
