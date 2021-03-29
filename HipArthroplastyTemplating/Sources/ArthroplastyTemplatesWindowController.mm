//
//  ArthroplastyTemplatesWindowController.m
//  HipArthroplastyTemplating
//  Created by Joris Heuberger on 04/04/07.
//  Copyright 2007-2016 OsiriX Team
//  Copyright 2017 volz.io
//

#import "ArthroplastyTemplatesWindowController+Private.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
#import <OsiriXAPI/BrowserController.h>
#import <OsiriXAPI/ViewerController.h>
#import <OsiriXAPI/ROI.h>
#import <OsiriXAPI/DCMView.h>
#import <OsiriXAPI/NSImage+N2.h>
#import <OsiriXAPI/N2Operators.h>
#import <OsiriXAPI/Notifications.h>
#pragma clang diagnostic pop

#import "ArthroplastyTemplateFamily.h"
#import "ArthroplastyTemplatingTemplateView.h"
#import "HipArthroplastyTemplating.h"
#include <cmath>
#include <algorithm>
#import "ArthroplastyTemplatesWindowController+Color.h"
#import "ArthroplastyTemplatesWindowController+Templates.h"
#import "NSBitmapImageRep+ArthroplastyTemplating.h"

#import "ArthroplastyTemplatingUserDefaults.h"

@interface ArthroplastyTemplatesWindowController ()

@property (assign) IBOutlet NSArrayController *familiesArrayController, *offsetsArrayController, *sizesArrayController;

@property (weak) IBOutlet ArthroplastyTemplatingTableView *familiesTableView;
@property (weak) IBOutlet ArthroplastyTemplatingTemplateView *pdfView;
@property (weak) IBOutlet NSSegmentedControl *projectionButtons, *sideButtons;
@property (weak) IBOutlet NSPopUpButton *sizesPopUp, *offsetsPopUp;
@property (weak) IBOutlet NSView *offsetsView;
@property (weak) IBOutlet NSSearchField *searchField;
@property (weak) IBOutlet NSButton *shouldTransformColor;
@property (weak) IBOutlet NSColorWell *transformColor;

@end

@implementation ArthroplastyTemplatesWindowController

@synthesize plugin = _plugin;

@synthesize side = _side;

@synthesize projection = _projection, projectionButtons = _projectionButtons;
@synthesize familiesArrayController = _familiesArrayController, offsetsArrayController = _offsetsArrayController, sizesArrayController = _sizesArrayController;
@synthesize family = _family;
@synthesize familiesTableView = _familiesTableView, searchField = _searchField;
@synthesize sizesPopUp = _sizesPopUp, offsetsPopUp = _offsetsPopUp, offsetsView = _offsetsView;
@synthesize shouldTransformColor = _shouldTransformColor, transformColor = _transformColor;

- (id)initWithPlugin:(HipArthroplastyTemplating *)plugin {
	if (!(self = [self initWithWindowNibName:@"ArthroplastyTemplatesWindow" owner:self]))
        return nil;
    
	_plugin = plugin;

    [self initTemplates];
    
	_projection = ArthroplastyTemplateAnteriorPosteriorProjection;
	
	NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    
	_selections = [[NSMutableDictionary alloc] init];
    [_selections addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:[bundle pathForResource:bundle.bundleIdentifier ofType:@"plist"]]];

	_templates = [[NSMutableArray alloc] init];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(performOsirixDragOperation:) name:OsirixPerformDragOperationNotification object:NULL];
    
    [self window];
    
    [self addObserver:self forKeyPath:@"family" options:0 context:ArthroplastyTemplatesWindowController.class];
    [self addObserver:self forKeyPath:@"offset" options:0 context:ArthroplastyTemplatesWindowController.class];
    [self addObserver:self forKeyPath:@"size" options:0 context:ArthroplastyTemplatesWindowController.class];

    [self addObserver:self forKeyPath:@"templat" options:0 context:ArthroplastyTemplatesWindowController.class];
    
    [self addObserver:self forKeyPath:@"side" options:0 context:ArthroplastyTemplatesWindowController.class];
    [self addObserver:self forKeyPath:@"projection" options:0 context:ArthroplastyTemplatesWindowController.class];
    
    [self addObserver:self forKeyPath:@"mustFlipHorizontally" options:0 context:ArthroplastyTemplatesWindowController.class];
    
	return self;
}

- (void)awakeFromNib {
//    [_pdfView setDisplayMode:kPDFDisplaySinglePage];
//    _pdfView.autoScales = YES;
    
//    _pdfView.scaleFactor = _pdfView.scaleFactorForSizeToFit;
	[self awakeColor];
    
    self.familiesArrayController.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)] ];
    
    self.offsetsArrayController.sortDescriptors = self.sizesArrayController.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES comparator:^NSComparisonResult(NSString *s1, NSString *s2) {
        unichar c10 = [s1 characterAtIndex:0];
        if (c10 >= '0' && c10 <= '9' && s1.floatValue == s2.floatValue) { // same numeric value, sort '00' before '0'
            if (s1.length > s2.length)
                return NSOrderedAscending;
             if (s1.length < s2.length)
                return NSOrderedDescending;
            return NSOrderedSame;
        }
        
        return [s1 compare:s2 options:NSNumericSearch|NSLiteralSearch|NSCaseInsensitiveSearch];
    }] ];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pdfViewDocumentDidChange:) name:ArthroplastyTemplatingTemplateViewDocumentDidChangeNotification object:_pdfView];
    
	[self awakeTemplates];
    
    [self.familiesArrayController addObserver:self forKeyPath:@"selection" options:NSKeyValueObservingOptionInitial context:ArthroplastyTemplatesWindowController.class];
    [self.offsetsArrayController addObserver:self forKeyPath:@"selection" options:NSKeyValueObservingOptionInitial context:ArthroplastyTemplatesWindowController.class];
    [self.sizesArrayController addObserver:self forKeyPath:@"selection" options:NSKeyValueObservingOptionInitial context:ArthroplastyTemplatesWindowController.class];
}

- (void)dealloc {
    [self.sizesArrayController removeObserver:self forKeyPath:@"selection" context:ArthroplastyTemplatesWindowController.class];
    [self.offsetsArrayController removeObserver:self forKeyPath:@"selection" context:ArthroplastyTemplatesWindowController.class];
    [self.familiesArrayController removeObserver:self forKeyPath:@"selection" context:ArthroplastyTemplatesWindowController.class];
    
    [self removeObserver:self forKeyPath:@"mustFlipHorizontally" context:ArthroplastyTemplatesWindowController.class];

    [self removeObserver:self forKeyPath:@"projection" context:ArthroplastyTemplatesWindowController.class];
    [self removeObserver:self forKeyPath:@"side" context:ArthroplastyTemplatesWindowController.class];
    
    [self removeObserver:self forKeyPath:@"templat" context:ArthroplastyTemplatesWindowController.class];
    
    [self removeObserver:self forKeyPath:@"size" context:ArthroplastyTemplatesWindowController.class];
    [self removeObserver:self forKeyPath:@"offset" context:ArthroplastyTemplatesWindowController.class];
    [self removeObserver:self forKeyPath:@"family" context:ArthroplastyTemplatesWindowController.class];

    [self deallocTemplates];
    
	[[NSNotificationCenter defaultCenter] removeObserver:self];
//	[_families release];
	[_templates release];
	[_selections release];
//    [_userDefaults release];
	[super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (context != ArthroplastyTemplatesWindowController.class)
        return [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    
    if (object == self.familiesArrayController && [keyPath isEqualToString:@"selection"]) {
        self.family = [self.familiesArrayController.selectedObjects.firstObject isKindOfClass:NSNull.class]? nil : self.familiesArrayController.selectedObjects.firstObject;
        return;
    }
    
    if (object == self.offsetsArrayController && [keyPath isEqualToString:@"selection"]) {
        self.offset = [self.offsetsArrayController.selectedObjects.firstObject isKindOfClass:NSNull.class]? nil : self.offsetsArrayController.selectedObjects.firstObject;
        return;
    }
    
    if (object == self.sizesArrayController && [keyPath isEqualToString:@"selection"]) {
        self.size = [self.sizesArrayController.selectedObjects.firstObject isKindOfClass:NSNull.class]? nil : self.sizesArrayController.selectedObjects.firstObject;
        return;
    }

    if (object != self)
        return;
    
    if ([keyPath isEqualToString:@"family"]) {
        NSString *previousOffset = [self.offsetsArrayController.selectedObjects firstObject];
        [self.offsetsArrayController removeObjectsAtArrangedObjectIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [self.offsetsArrayController.arrangedObjects count])]];
        for (NSString *offset in [NSSet setWithArray:[self.family.templates valueForKeyPath:@"offset"]])
            [self.offsetsArrayController addObject:offset];
        [ArthroplastyTemplatesWindowController arrayController:self.offsetsArrayController selectObjectClosestTo:previousOffset];
        [self observeValueForKeyPath:@"offset" ofObject:self change:nil context:ArthroplastyTemplatesWindowController.class];
        return;
    }
    
    if ([keyPath isEqualToString:@"offset"]) {
        NSString *previousSize = [self.sizesArrayController.selectedObjects firstObject];
        [self.sizesArrayController removeObjectsAtArrangedObjectIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [self.sizesArrayController.arrangedObjects count])]];
        NSArray *templates = self.family.templates;
        if (self.offset)
            templates = [templates filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"offset = %@", self.offset]];
        for (NSString *size in [NSSet setWithArray:[templates valueForKeyPath:@"size"]])
            [self.sizesArrayController addObject:size];
        [ArthroplastyTemplatesWindowController arrayController:self.sizesArrayController selectObjectClosestTo:previousSize];
        [self observeValueForKeyPath:@"size" ofObject:self change:nil context:ArthroplastyTemplatesWindowController.class];
        return;
    }
    
    if ([keyPath isEqualToString:@"size"]) {
        self.templat = [self.family templateMatchingOffset:self.offset size:self.size side:self.side];
        return;
    }
    
    // no return zone
    
    if ([keyPath isEqualToString:@"templat"]) {
        ArthroplastyTemplate *templat = self.templat;
        
        // available projections
        BOOL hasML = ([templat pdfPathForProjection:ArthroplastyTemplateMedialLateralProjection] != nil);
        [self.projectionButtons setEnabled:hasML forSegment:1]; // segment 1 is ML
        if (!hasML)
            self.projection = ArthroplastyTemplateAnteriorPosteriorProjection;
        
        // available sides
        ArthroplastyTemplateSide allowedSides = [templat allowedSides];
        if ((allowedSides&ArthroplastyTemplateBothSides) != ArthroplastyTemplateBothSides) { // this template doesnt support both sides... look for the other side's template
            if ([templat templateForOtherPatientSide])
                allowedSides = ArthroplastyTemplateBothSides;
        }
        
        [self.sideButtons setEnabled:(allowedSides&ArthroplastyTemplateRightSide) forSegment:0];
        [self.sideButtons setEnabled:(allowedSides&ArthroplastyTemplateLeftSide) forSegment:1];
    }
    
    if ([@[ @"templat", @"projection" ] containsObject:keyPath]) {
        NSString *path = [self.templat pdfPathForProjection:self.projection];
        [self.pdfView setDocument:(path? [[[PDFDocument alloc] initWithURL:[NSURL fileURLWithPath:path]] autorelease] : nil)];
    }
    
    if ([keyPath isEqualToString:@"mustFlipHorizontally"]) {
        [self.pdfView setNeedsDisplay:YES];
    }
}

+ (void)arrayController:(NSArrayController *)ac selectObjectClosestTo:(NSString *)value {
#warning TODO
}

- (NSString *)windowFrameAutosaveName {
	return @"ArthroplastyTemplatesWindow";
}

- (void)windowWillClose:(NSNotification *)aNotification {
	// [self autorelease];
}

//- (NSSize)windowWillResize:(NSWindow *)window toSize:(NSSize)size {
//	return NSMakeSize(std::max(size.width, 208.f), std::max(size.height, 200.f));
//}

#pragma mark PDF preview

- (NSString *)idForTemplate:(ArthroplastyTemplate *)templat {
    if (!templat)
        return nil;
    
    NSMutableArray<NSString *> *comps = [NSMutableArray array];
    [comps addObject:templat.manufacturer];
    [comps addObject:templat.name];
    if (templat.offset.length)
        [comps addObject:templat.offset];
    [comps addObject:templat.size];
    
	if (_projection == ArthroplastyTemplateMedialLateralProjection)
        [comps addObject:@"Lateral"];
    
    return [comps componentsJoinedByString:@"/"];
}

- (BOOL)selectionForTemplate:(ArthroplastyTemplate *)templat into:(NSRect *)rect {
	NSRect temp;
	NSString *key = [self idForTemplate:templat];
	if ([[HipArthroplastyTemplating userDefaults] keyExists:key])
		temp = [[HipArthroplastyTemplating userDefaults] rect:key otherwise:NSZeroRect];
	else if ([_selections valueForKey:key]) {
		temp = [ArthroplastyTemplatingUserDefaults NSRectFromData:[_selections valueForKey:key] otherwise:NSZeroRect];
	} else return NO;
	if (temp.size.width < 0) { temp.origin.x += temp.size.width; temp.size.width = -temp.size.width; }
	if (temp.size.height < 0) { temp.origin.y += temp.size.height; temp.size.height = -temp.size.height; }
	memcpy(rect, &temp, sizeof(NSRect));
	return YES;	
}

- (BOOL)selectionForCurrentTemplate:(NSRect *)rect {
	return [self selectionForTemplate:self.templat into:rect];
}

- (void)setSelectionForCurrentTemplate:(NSRect)rect {
	[[HipArthroplastyTemplating userDefaults] setRect:rect forKey:[self idForTemplate:self.templat]];
}

+ (void)flipHorizontallyImage:(NSImage *)image {
	// bitmap init
	NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc] initWithData:[image TIFFRepresentation]];
	// flip
	vImage_Buffer src, dest;
	src.height = dest.height = bitmap.pixelsHigh;
	src.width = dest.width = bitmap.pixelsWide;
	src.rowBytes = dest.rowBytes = [bitmap bytesPerRow];
	src.data = dest.data = [bitmap bitmapData];
	vImageHorizontalReflect_ARGB8888(&src, &dest, 0L);
	// draw
	[image lockFocus];
	[bitmap draw];
	[image unlockFocus];
	// release
	[bitmap release];
}

+ (void)bitmap:(NSBitmapImageRep *)bitmap setColor:(NSColor *)color {
    NSColorSpace *colorSpace = [bitmap colorSpace];
    size_t spp = [bitmap samplesPerPixel];
    NSUInteger samples[spp];
    CGFloat fsamples[spp];
	for (NSInteger y = bitmap.pixelsHigh-1; y >= 0; --y)
		for (NSInteger x = bitmap.pixelsWide-1; x >= 0; --x) {
			[bitmap getPixel:samples atX:x y:y];
            for (int i = 0; i < spp; ++i)
                fsamples[i] = samples[i]*1.0/255;
            
            NSColor *xycolor = [NSColor colorWithColorSpace:colorSpace components:fsamples count:spp];
            
            CGFloat brightness, alpha;
            [[xycolor colorUsingColorSpaceName:NSCalibratedRGBColorSpace] getHue:NULL saturation:NULL brightness:&brightness alpha:&alpha];
            NSColor *fixedColor = [NSColor colorWithDeviceHue:[color hueComponent] saturation:[color saturationComponent] brightness:std::max((CGFloat).75, brightness) alpha:alpha];

            xycolor = [fixedColor colorUsingColorSpace:colorSpace];
            [color getComponents:fsamples];
            fsamples[spp-1] = alpha;
            
            for (int i = 0; i < spp; ++i)
                samples[i] = floor(fsamples[i]*255);

            [bitmap setPixel:samples atX:x y:y];
		}
}

- (N2Image *)templateImage:(ArthroplastyTemplate *)templat entirePageSizePixels:(NSSize)size color:(NSColor *)color {
	N2Image *image = [[N2Image alloc] initWithContentsOfFile:[templat pdfPathForProjection:_projection]];
//    image.size *= templat.scale;
    
	NSSize imageSize = [image size];
	
	// size.width OR size.height can be qual to zero, in which case the zero value is set corresponding to the available value
	if (!size.width)
		size.width = std::floor(size.height/imageSize.height*imageSize.width);
	if (!size.height)
		size.height = std::floor(size.width/imageSize.width*imageSize.height);
	
	[image setScalesWhenResized:YES];
	[image setSize:size];
	
	// extract selected part
	NSRect sel; if ([self selectionForTemplate:templat into:&sel]) {
		sel = NSMakeRect(std::floor(sel.origin.x*size.width), std::floor(sel.origin.y*size.height), std::ceil(sel.size.width*size.width), std::ceil(sel.size.height*size.height));
		N2Image *temp = [image crop:sel];
		[image release];
		image = [temp retain];
	}
	
	if ([self mustFlipHorizontally:templat])
		[[self class] flipHorizontallyImage:image];

	N2Image *temp = [[N2Image alloc] initWithSize:[image size] inches:[image inchSize] portion:[image portion]];
	NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc] initWithData:[image TIFFRepresentation]];

	[bitmap detectAndApplyBorderTransparency:8];
	if (color)
		[[self class] bitmap:bitmap setColor:color]; // [bitmap setColor:color];

	[temp addRepresentation:bitmap];
	[bitmap release];
	
	[image release];
	image = temp;

	return [image autorelease];
}

- (N2Image *)templateImage:(ArthroplastyTemplate *)templat entirePageSizePixels:(NSSize)size {
	return [self templateImage:templat entirePageSizePixels:size color:[_shouldTransformColor state]? [_transformColor color] : NULL];
}

- (N2Image *)templateImage:(ArthroplastyTemplate *)templat {
	PDFPage *page = [_pdfView currentPage];
	NSRect pageBox = [_pdfView convertRect:[page boundsForBox:kPDFDisplayBoxMediaBox] fromPage:page];
	pageBox.size = n2::round(pageBox.size);
	return [self templateImage:templat entirePageSizePixels:pageBox.size];
}

- (N2Image *)dragImageForTemplate:(ArthroplastyTemplate *)templat {
	return [self templateImage:templat];
}

#pragma mark Flip Left/Right

+ (NSSet *)keyPathsForValuesAffectingMustFlipHorizontally {
    return [NSSet setWithObjects: @"templat", @"side", nil];
}

- (BOOL)mustFlipHorizontally {
    return [self mustFlipHorizontally:self.templat];
}

- (BOOL)mustFlipHorizontally:(ArthroplastyTemplate *)t {
	if ((t.allowedSides&ArthroplastyTemplateBothSides) != ArthroplastyTemplateBothSides)
        return NO; // cant flip!
    
    return (self.side&ArthroplastyTemplateBothSides) != (t.side&ArthroplastyTemplateBothSides);
}

#pragma mark Drag&Drop

- (void)addTemplate:(ArthroplastyTemplate *)templat toPasteboard:(NSPasteboard *)pboard {
	[pboard declareTypes:[NSArray arrayWithObjects:pasteBoardOsiriXPlugin, @"ArthroplastyTemplate*", NULL] owner:self];
	[pboard setData:[NSData dataWithBytes:&templat length:sizeof(ArthroplastyTemplate *)] forType:@"ArthroplastyTemplate*"];
}

- (BOOL)tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard {
    [self addTemplate:[[self familyAtIndex:[rowIndexes firstIndex]] templateMatchingOffset:self.offsetsPopUp.titleOfSelectedItem size:self.sizesPopUp.titleOfSelectedItem side:self.side] toPasteboard:pboard];
	return YES;
}

- (void)dragTemplate:(ArthroplastyTemplate *)templat startedByEvent:(NSEvent *)event onView:(NSView *)view {
	NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSDragPboard];
	[self addTemplate:templat toPasteboard:pboard];
	
	N2Image *image = [self dragImageForTemplate:templat];
	
	NSPoint click = [view convertPoint:[event locationInWindow] fromView:NULL];
	
	NSSize size = [image size];
	NSPoint o = NSMakePoint(size)/2;
	if ([templat origin:&o forProjection:_projection]) { // origin in inches
		o = [image convertPointFromPageInches:o];
		if ([self mustFlipHorizontally:templat])
			o.x = size.width-o.x;
	}

	[view dragImage:image at:click-o-NSMakePoint(1,-3) offset:NSMakeSize(0,0) event:event pasteboard:pboard source:view slideBack:YES];
}

- (ROI *)createROIFromTemplate:(ArthroplastyTemplate *)templat inViewer:(ViewerController *)destination centeredAt:(NSPoint)p {
	N2Image *image = [self templateImage:templat entirePageSizePixels:NSMakeSize(0,1000)]; // TODO: N -> adapted size
    
   // NSBitmapImageRep *bitmap = [[image representations] objectAtIndex:0];
//    NSSize pixelSize = NSMakeSize(bitmap.pixelsWide, bitmap.pixelsHigh);
	
//	CGFloat magnification = [[_plugin windowControllerForViewer:destination] magnification];
//	if (!magnification) magnification = 1;
	float pixSpacing = (1.0 / [image resolution] * 25.4); // image is in 72 dpi, we work in millimeters
	
	ROI *newLayer = [destination addLayerRoiToCurrentSliceWithImage:image referenceFilePath:[templat path] layerPixelSpacingX:pixSpacing layerPixelSpacingY:pixSpacing];
	
//	[[newLayer pix] setPixel ];
	
	[destination bringToFrontROI:newLayer];
	[newLayer generateEncodedLayerImage];
	
	// find the center of the template
	NSSize imageSize = [image size];
	NSPoint imageCenter = NSMakePoint(imageSize/2);
	NSPoint o;
	if ([templat origin:&o forProjection:_projection]) { // origin in inches
		o = [image convertPointFromPageInches:o];
		if ([self mustFlipHorizontally:templat])
			o.x = imageSize.width-o.x;
		imageCenter = o;
		imageCenter.y = imageSize.height-imageCenter.y;
	}
	
	NSArray *layerPoints = [newLayer points];
	NSPoint layerSize = [[layerPoints objectAtIndex:2] point] - [[layerPoints objectAtIndex:0] point];
	
	NSPoint layerCenter = imageCenter/imageSize*layerSize;
	[[newLayer points] addObject:[MyPoint point:layerCenter]]; // center, index 4

	[newLayer setROIMode:ROI_selected]; // in order to make the roiMove method possible
	[newLayer rotate:[templat rotation]/M_PI*180*([self mustFlipHorizontally:templat]?-1:1) :layerCenter];

	[[newLayer points] addObject:[MyPoint point:layerCenter+NSMakePoint(1,0)]]; // rotation reference, index 5
	
	// stem-cup magnets, indexes 6, 7, 8, 9, 10 for S, M, L, XL, XXL
	for (NSValue *value in [templat headRotationPointsForProjection:_projection]) {
		NSPoint point = [value pointValue];
		point = [image convertPointFromPageInches:point];
		if ([self mustFlipHorizontally:templat])
			point.x = imageSize.width-point.x;
		point.y = imageSize.height-point.y;
		point = point/imageSize*layerSize;
		[[newLayer points] addObject:[MyPoint point:point]];
	}
	
	// proximal-distal magnets, indexes 11, 12, 13, 14 for A, A2, B, B2; currently only A and A2 seem to be used
	for (NSValue *value in [templat matingPointsForProjection:_projection]) {
		NSPoint point = [value pointValue];
		point = [image convertPointFromPageInches:point];
		if ([self mustFlipHorizontally:templat])
			point.x = imageSize.width-point.x;
		point.y = imageSize.height-point.y;
		point = point/imageSize*layerSize;
		[[newLayer points] addObject:[MyPoint point:point]];
	}
	
	[newLayer roiMove:p-layerCenter :YES];
	
	// set the textual data
	[newLayer setName:[templat name]];
	NSArray *lines = [templat textualData];
	if (lines[0]) [newLayer setTextualBoxLine1:lines[0]];
	if (lines[1]) [newLayer setTextualBoxLine2:lines[1]];
	if (lines[2]) [newLayer setTextualBoxLine3:lines[2]];
	if (lines[3]) [newLayer setTextualBoxLine4:lines[3]];
	if (lines[4]) [newLayer setTextualBoxLine5:lines[4]];
 
	[[NSNotificationCenter defaultCenter] postNotificationName:OsirixROIChangeNotification object:newLayer userInfo: nil];
	
	return newLayer;
}

- (void)performOsirixDragOperation:(NSNotification *)note {
	NSDictionary *userInfo = note.userInfo;
	id <NSDraggingInfo> operation = [userInfo valueForKey:@"id<NSDraggingInfo>"];

	if (![[operation draggingPasteboard] dataForType:@"ArthroplastyTemplate*"])
		return; // no ArthroplastyTemplate pointer available
	
	ViewerController *destination = [note object];
	
	ArthroplastyTemplate *templat = nil;
    
    [[[operation draggingPasteboard] dataForType:@"ArthroplastyTemplate*"] getBytes:&templat length:sizeof(ArthroplastyTemplate *)];

	// find the location of the mouse in the OpenGL view
	NSPoint openGLLocation = [[destination imageView] ConvertFromNSView2GL:[[destination imageView] convertPoint: [destination.imageView convertPoint: [NSEvent mouseLocation] fromView: nil] fromView:NULL]];
	
	[self createROIFromTemplate:templat inViewer:destination centeredAt:openGLLocation];
	
	[[destination window] makeKeyWindow];
	
	return;
}

- (NSRect)addMargin:(int)pixels toRect:(NSRect)rect {
	float x = rect.origin.x - pixels;
	if (x<0) x=0;
	float y = rect.origin.y - pixels;
	if (y<0) y=0;
	return NSMakeRect(x, y, rect.size.width + 2 * pixels, rect.size.height + 2 * pixels);
}

#pragma mark New

- (void)pdfViewDocumentDidChange:(NSNotification *)note {
	BOOL enable = (_pdfView.document != nil);
	[self.sideButtons setEnabled:enable];
	[self.sizesPopUp setEnabled:enable];
}

+ (NSSet *)keyPathsForValuesAffectingProjectionTag {
    return [NSSet setWithObject:@"projection"];
}

- (NSInteger)projectionTag {
    if (self.projection == ArthroplastyTemplateMedialLateralProjection)
        return 1; // ML
    return 0; // AP
}

- (void)setProjectionTag:(NSInteger)tag {
    ArthroplastyTemplateProjection projection = ArthroplastyTemplateAnteriorPosteriorProjection;
    if (tag == 1)
        projection = ArthroplastyTemplateMedialLateralProjection;
    
    self.projection = projection;
}

+ (NSSet *)keyPathsForValuesAffectingSideTag {
    return [NSSet setWithObject:@"side"];
}

- (NSInteger)sideTag {
    if (self.side == ArthroplastyTemplateLeftSide)
        return 1; // left
    return 0; // right
}

- (void)setSideTag:(NSInteger)tag {
    ArthroplastyTemplateSide side = ArthroplastyTemplateRightSide;
    if (tag == 1)
        side = ArthroplastyTemplateLeftSide;
    
    self.side = side;
}

+ (NSSet *)keyPathsForValuesAffectingOffsetsEnabled {
    return [NSSet setWithObjects: @"family", nil];
}

- (BOOL)offsetsEnabled {
    NSMutableSet *offsets = [NSMutableSet setWithArray:[self.family.templates valueForKeyPath:@"offset"]];
    [offsets removeObject:NSNull.null];
    return (offsets.count != 0);
}

- (void)keyDown:(NSEvent *)event {
    NSUInteger offsetsIndex = [self.offsetsArrayController selectionIndex], offsetsCount = [self.offsetsArrayController.arrangedObjects count];
    NSUInteger sizesIndex = [self.sizesArrayController selectionIndex], sizesCount = [self.sizesArrayController.arrangedObjects count];
    
    if ([event.characters isEqualToString:@"+"]) {
        if (sizesIndex < sizesCount-1)
            self.sizesArrayController.selectionIndex += 1;
        else if (offsetsIndex < offsetsCount-1) {
            self.offsetsArrayController.selectionIndex += 1;
            self.sizesArrayController.selectionIndex = 0;
        }
        
        return;
    }
    
    if ([event.characters isEqualToString:@"-"]) {
        if (sizesIndex > 0)
            self.sizesArrayController.selectionIndex -= 1;
        else if (offsetsIndex > 0) {
            self.offsetsArrayController.selectionIndex -= 1;
            self.sizesArrayController.selectionIndex = [self.sizesArrayController.arrangedObjects count]-1;
        }
        
        return;
    }
    
    [super keyDown:event];
}

@end
