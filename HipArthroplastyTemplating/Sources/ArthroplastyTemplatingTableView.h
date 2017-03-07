//
//  ArthroplastyTemplatingTableView.h
//  HipArthroplastyTemplating
//  Copyright 2007-2016 OsiriX Team
//  Copyright 2017 volz.io
//

#import <Cocoa/Cocoa.h>
#import "ArthroplastyTemplatingWindowController.h"

@interface ArthroplastyTemplatingTableView : NSTableView {
	IBOutlet ArthroplastyTemplatingWindowController *_controller;
}

@end
