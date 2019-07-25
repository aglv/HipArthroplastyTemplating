//
//  ArthroplastyTemplatesWindowController.h
//  HipArthroplastyTemplating
//  Created by Joris Heuberger on 04/04/07.
//  Copyright 2007-2016 OsiriX Team
//  Copyright 2017 volz.io
//

#import <Cocoa/Cocoa.h>
#import "SelectablePDFView.h"
#import "ArthroplastyTemplate.h"

@class ArthroplastyTemplatingTableView, N2Image, ROI, ViewerController;
@class ArthroplastyTemplateFamily, HipArthroplastyTemplating;
@class ArthroplastyTemplatesWindowControllerTemplatesHelper;

@interface ArthroplastyTemplatesWindowController : NSWindowController {
	__unsafe_unretained HipArthroplastyTemplating *_plugin;

    NSMutableArray *_templates;

    NSMutableDictionary *_selections;
    
    // IBOutlets

    NSArrayController *_familiesArrayController, *_offsetsArrayController, *_sizesArrayController;

    ArthroplastyTemplatingTableView *_familiesTableView;
    SelectablePDFView *_pdfView;
	NSPopUpButton *_sizesPopUp, *_offsetsPopUp;
    NSView *_offsetsView;
	IBOutlet NSButton *_shouldTransformColor;
	IBOutlet NSColorWell *_transformColor;
	NSSegmentedControl *_projectionButtons, *_sideButtons;
	NSSearchField *_searchField;
	ArthroplastyTemplateProjection _projection;
	
}

@property (readonly) HipArthroplastyTemplating *plugin;

@property (retain) ArthroplastyTemplateFamily *family;
@property (retain) NSString *offset;
@property (retain) NSString *size;

@property (retain) ArthroplastyTemplate *templat; // because 'template' is reserved in C++

@property ArthroplastyTemplateSide side;
@property ArthroplastyTemplateProjection projection;

@property (assign) IBOutlet NSArrayController *familiesArrayController, *offsetsArrayController, *sizesArrayController;

@property (weak) IBOutlet ArthroplastyTemplatingTableView *familiesTableView;
@property (weak) IBOutlet SelectablePDFView *pdfView;
@property (weak) IBOutlet NSSegmentedControl *projectionButtons, *sideButtons;
@property (weak) IBOutlet NSPopUpButton *sizesPopUp, *offsetsPopUp;
@property (weak) IBOutlet NSView *offsetsView;
@property (weak) IBOutlet NSSearchField *searchField;

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
