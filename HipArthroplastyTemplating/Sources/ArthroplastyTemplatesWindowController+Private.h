//
//  ArthroplastyTemplatesWindowController+Private.h
//  HipArthroplastyTemplating
//
//  Created by Alessandro Volz on 7/23/19.
//

#ifndef ArthroplastyTemplatesWindowController_Private_h
#define ArthroplastyTemplatesWindowController_Private_h

#import "ArthroplastyTemplatesWindowController.h"

@class ArthroplastyTemplatingTemplateView;
@class ArthroplastyTemplatingTableView;

@interface ArthroplastyTemplatesWindowController () {
    // IBOutlets
    __unsafe_unretained NSArrayController *_familiesArrayController, *_offsetsArrayController, *_sizesArrayController;
    __unsafe_unretained ArthroplastyTemplatingTableView *_familiesTableView;
    __unsafe_unretained ArthroplastyTemplatingTemplateView *_pdfView;
    __unsafe_unretained NSPopUpButton *_sizesPopUp, *_offsetsPopUp;
    __unsafe_unretained NSView *_offsetsView;
    __unsafe_unretained NSButton *_shouldTransformColor;
    __unsafe_unretained NSColorWell *_transformColor;
    __unsafe_unretained NSSegmentedControl *_projectionButtons, *_sideButtons;
    __unsafe_unretained NSSearchField *_searchField;
}

//@property (assign) ArthroplastyTemplateFamily *family;

@end

#endif /* ArthroplastyTemplatesWindowController_Private_h */
