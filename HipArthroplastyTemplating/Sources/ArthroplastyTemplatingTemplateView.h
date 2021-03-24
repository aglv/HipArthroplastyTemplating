//
//  ArthroplastyTemplatingTemplateView.h
//  HipArthroplastyTemplating
//  Created by Alessandro Volz on 6/8/09.
//  Copyright 2007-2016 OsiriX Team
//  Copyright 2017 volz.io
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
#import "ArthroplastyTemplatesWindowController.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const ArthroplastyTemplatingTemplateViewDocumentDidChangeNotification;

@interface ArthroplastyTemplatingTemplateView : PDFView {
	BOOL _selected, _selectionInitiated, _drawing;
	NSRect _selectedRect;
	NSPoint _mouseDownLocation;
}

@property (nonatomic, weak, nullable) ArthroplastyTemplatesWindowController<PDFViewDelegate> *delegate;

@end

NS_ASSUME_NONNULL_END
