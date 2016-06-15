//
//  ArthroplastyTemplatingTableView.m
//  HipArthroplastyTemplating
//  Copyright 2007-2016 OsiriX Team
//  Copyright 2016 volz.io
//

#import "ArthroplastyTemplatingTableView.h"
#import "ArthroplastyTemplatingWindowController+Templates.h"
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
#import <OsiriX/NSImage+N2.h>
#import <OsiriX/N2Operators.h>
#pragma clang diagnostic pop

@implementation ArthroplastyTemplatingTableView

-(NSImage*)dragImageForRowsWithIndexes:(NSIndexSet*)dragRows tableColumns:(NSArray*)cols event:(NSEvent*)event offset:(NSPointPointer)offset {
	if ([dragRows count] >1) return NULL;
	[self selectRowIndexes:dragRows byExtendingSelection:NO];
	[self setNeedsDisplay:YES];
    
    ArthroplastyTemplate* t = [_controller currentTemplate];
	N2Image* image = [_controller dragImageForTemplate:t];
    
    
    NSPoint o = NSZeroPoint;
    if ([t origin:&o forDirection:_controller.templateDirection]) { // origin in inches
		o = [image convertPointFromPageInches:o];
		if (![_controller mustFlipHorizontally:t])
			o.x = image.size.width-o.x;
        if (!image.isFlipped)
            o.y = image.size.height-o.y;
	}
    
    *offset = o-image.size/2-NSMakePoint(1,-3);
    
    return image;
}

-(BOOL)canDragRowsWithIndexes:(NSIndexSet *)rowIndexes atPoint:(NSPoint)mouseDownPoint {
	return YES;
}

@end
