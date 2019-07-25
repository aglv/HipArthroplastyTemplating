//
//  ArthroplastyTemplatingTableView.m
//  HipArthroplastyTemplating
//  Copyright 2007-2016 OsiriX Team
//  Copyright 2017 volz.io
//

#import "ArthroplastyTemplatingTableView.h"
#import "ArthroplastyTemplatesWindowController+Templates.h"
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
#import <OsiriXAPI/NSImage+N2.h>
#import <OsiriXAPI/N2Operators.h>
#pragma clang diagnostic pop

@implementation ArthroplastyTemplatingTableView

- (NSImage *)dragImageForRowsWithIndexes:(NSIndexSet *)dragRows tableColumns:(NSArray *)cols event:(NSEvent *)event offset:(NSPointPointer)offset {
    if (dragRows.count != 1)
        return nil;

    [self selectRowIndexes:dragRows byExtendingSelection:NO];
    [self setNeedsDisplay:YES];
    
    ArthroplastyTemplatesWindowController *controller = (id)self.delegate;
    if (![controller isKindOfClass:ArthroplastyTemplatesWindowController.class])
        return nil;
    
    ArthroplastyTemplate *t = [controller templat];
	N2Image *image = [controller dragImageForTemplate:t];
    
    NSPoint o = NSZeroPoint;
    if ([t origin:&o forProjection:controller.projection]) { // origin in inches
		o = [image convertPointFromPageInches:o];
		if (![controller mustFlipHorizontally:t])
			o.x = image.size.width-o.x;
        if (!image.isFlipped)
            o.y = image.size.height-o.y;
	}
    
    *offset = o-image.size/2-NSMakePoint(1, -3);
    
    return image;
}

- (BOOL)canDragRowsWithIndexes:(NSIndexSet *)indexes atPoint:(NSPoint)mouseDownPoint {
	return (indexes.count == 1);
}

@end
