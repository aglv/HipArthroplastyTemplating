//
//  ArthroplastyTemplatesWindowController.h
//  HipArthroplastyTemplating
//  Created by Joris Heuberger on 04/04/07.
//  Copyright 2007-2016 OsiriX Team
//  Copyright 2017 volz.io
//

#import <Cocoa/Cocoa.h>
#import <Quartz/PDFKit.h>
#import "ArthroplastyTemplate.h"

@class ArthroplastyTemplatingTableView, N2Image, ROI, ViewerController;
@class ArthroplastyTemplate, ArthroplastyTemplateFamily, HipArthroplastyTemplating;
@class ArthroplastyTemplatesWindowControllerTemplatesHelper;
@class ArthroplastyTemplatingTemplateView;

@interface ArthroplastyTemplatesWindowController : NSWindowController<PDFViewDelegate> {
	__unsafe_unretained HipArthroplastyTemplating *_plugin;

    NSMutableArray<ArthroplastyTemplate *> *_templates;

    NSMutableDictionary<NSString *, NSData *> *_selections;

    ArthroplastyTemplateSide _side;
    ArthroplastyTemplateProjection _projection;
}

@property (weak, readonly) HipArthroplastyTemplating *plugin;

@property (retain) ArthroplastyTemplateFamily *family;
@property (retain) NSString *offset;
@property (retain) NSString *size;

@property (retain) ArthroplastyTemplate *templat; // because 'template' is reserved in C++

@property ArthroplastyTemplateSide side;
@property ArthroplastyTemplateProjection projection;

@property NSInteger projectionTag, sideTag;
@property (readonly) BOOL offsetsEnabled;

@property (readonly) BOOL mustFlipHorizontally;

- (id)initWithPlugin:(HipArthroplastyTemplating *)plugin;

- (BOOL)mustFlipHorizontally:(ArthroplastyTemplate *)t;

- (N2Image *)dragImageForTemplate:(ArthroplastyTemplate *)templat;

- (void)setSide:(ArthroplastyTemplateSide)side;

- (ROI *)createROIFromTemplate:(ArthroplastyTemplate *)templat inViewer:(ViewerController *)destination centeredAt:(NSPoint)p;
- (void)dragTemplate:(ArthroplastyTemplate *)templat startedByEvent:(NSEvent *)event onView:(NSView *)view;

- (NSRect)addMargin:(int)pixels toRect:(NSRect)rect;

- (BOOL)selectionForCurrentTemplate:(NSRect *)rect;
- (void)setSelectionForCurrentTemplate:(NSRect)rect;

@end
