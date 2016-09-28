//
//  ArthroplastyTemplatingWindowController.h
//  HipArthroplastyTemplating
//  Created by Joris Heuberger on 04/04/07.
//  Copyright 2007-2016 OsiriX Team
//  Copyright 2016 volz.io
//

#import <Cocoa/Cocoa.h>
#import "SelectablePDFView.h"
#import "ArthroplastyTemplate.h"

@class ArthroplastyTemplatingTableView, N2Image, ROI, ViewerController;
@class ArthroplastyTemplateFamily, HipArthroplastyTemplating;
#import "ArthroplastyTemplatingUserDefaults.h"


@interface ArthroplastyTemplatingWindowController : NSWindowController {
	NSMutableArray* _templates;
	HipArthroplastyTemplating* _plugin;

	NSArrayController* _familiesArrayController;
	IBOutlet ArthroplastyTemplatingTableView* _familiesTableView;
	
	IBOutlet SelectablePDFView* _pdfView;
	IBOutlet NSPopUpButton* _sizes;
	IBOutlet NSButton* _shouldTransformColor;
	IBOutlet NSColorWell* _transformColor;
	IBOutlet NSSegmentedControl* _viewDirectionControl;
	IBOutlet NSSearchField* _searchField;
	ArthroplastyTemplateViewDirection _viewDirection;
	IBOutlet NSSegmentedControl* _sideControl;
	
	ArthroplastyTemplatingUserDefaults* _userDefaults;
	NSMutableDictionary* _presets;
}

@property(readonly) BOOL mustFlipHorizontally;
@property(readonly) ArthroplastyTemplatingUserDefaults* userDefaults;
@property(readonly) HipArthroplastyTemplating* plugin;
@property(readonly) ArthroplastyTemplateViewDirection templateDirection;

@property(assign) IBOutlet NSArrayController* familiesArrayController;

-(id)initWithPlugin:(HipArthroplastyTemplating*)plugin;

-(BOOL)mustFlipHorizontally:(ArthroplastyTemplate*)t;

-(NSString*)pdfPathForFamilyAtIndex:(NSInteger)index;
-(N2Image*)dragImageForTemplate:(ArthroplastyTemplate*)templat;

-(void)setFamily:(id)sender;
-(IBAction)setViewDirection:(id)sender;

-(IBAction)setSideAction:(id)sender;
-(void)setSide:(ATSide)side;

-(ROI*)createROIFromTemplate:(ArthroplastyTemplate*)templat inViewer:(ViewerController*)destination centeredAt:(NSPoint)p;
-(void)dragTemplate:(ArthroplastyTemplate*)templat startedByEvent:(NSEvent*)event onView:(NSView*)view;

-(NSRect)addMargin:(int)pixels toRect:(NSRect)rect;

-(BOOL)selectionForCurrentTemplate:(NSRect*)rect;
-(void)setSelectionForCurrentTemplate:(NSRect)rect;

-(ATSide)side;

@end
