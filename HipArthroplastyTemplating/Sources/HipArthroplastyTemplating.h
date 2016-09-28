//
//  HipArthroplastyTemplating.h
//  HipArthroplastyTemplating
//  Created by Joris Heuberger on 04/04/07.
//  Copyright 2007-2016 OsiriX Team
//  Copyright 2016 volz.io
//

#import <Foundation/Foundation.h>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
#import <OsiriX/PluginFilter.h>
#pragma clang diagnostic pop

@class ArthroplastyTemplatingWindowController, ArthroplastyTemplatingStepsController;

@interface HipArthroplastyTemplating : PluginFilter {
	ArthroplastyTemplatingWindowController *_templatesWindowController;
	NSMutableArray* _windows;
	BOOL _initialized;
}

@property(readonly) ArthroplastyTemplatingWindowController* templatesWindowController;

-(ArthroplastyTemplatingStepsController*)windowControllerForViewer:(ViewerController*)viewer;

@end
