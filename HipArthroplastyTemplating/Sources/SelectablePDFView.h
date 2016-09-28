//
//  SelectablePDFView.h
//  HipArthroplastyTemplating
//  Created by Alessandro Volz on 6/8/09.
//  Copyright 2007-2016 OsiriX Team
//  Copyright 2016 volz.io
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
@class ArthroplastyTemplatingWindowController;

extern NSString* SelectablePDFViewDocumentDidChangeNotification;

@interface SelectablePDFView : PDFView {
	BOOL _selected, _selectionInitiated;
	NSRect _selectedRect;
	NSPoint _mouseDownLocation;
	IBOutlet ArthroplastyTemplatingWindowController* _controller;
}

@end
