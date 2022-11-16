//
//  NSBitmapImageRep+ArthroplastyTemplating.h
//  HipArthroplastyTemplating
//  Created by Alessandro Volz on 2/1/10.
//  Copyright 2007-2016 OsiriX Team
//  Copyright 2017 volz.io
//

#import <Cocoa/Cocoa.h>


@interface NSBitmapImageRep (ArthroplastyTemplating)

- (void)ArthroplastyTemplating_detectAndApplyBorderTransparency:(uint8)alphaThreshold;
//- (void)ArthroplastyTemplating_setColor:(NSColor *)color;

@end
