//
//  ArthroplastyTemplatingPDFView.h
//  HipArthroplastyTemplating
//  Created by Alessandro Volz on 6/8/09.
//  Copyright 2007-2016 OsiriX Team
//  Copyright 2017 volz.io
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>

@class ArthroplastyTemplatesWindowController;

extern NSString * const ArthroplastyTemplatingPDFViewDocumentDidChangeNotification;

@interface ArthroplastyTemplatingPDFView : PDFView {
	BOOL _selected, _selectionInitiated, _drawing;
	NSRect _selectedRect;
	NSPoint _mouseDownLocation;
//    IBOutlet ArthroplastyTemplatesWindowController *_controller;
}

- (ArthroplastyTemplatesWindowController *)controller;

@end
