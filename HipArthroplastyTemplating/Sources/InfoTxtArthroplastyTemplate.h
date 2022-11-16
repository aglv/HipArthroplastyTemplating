//
//  InfoTxtArthroplastyTemplate.h
//  HipArthroplastyTemplating
//  Created by Joris Heuberger on 19/03/07.
//  Copyright 2007-2016 OsiriX Team
//  Copyright 2017 volz.io
//

#import <Cocoa/Cocoa.h>
#import "ArthroplastyTemplate.h"

@interface InfoTxtArthroplastyTemplate : ArthroplastyTemplate {
	NSDictionary *_properties;
}

- (instancetype)initFromFileAtPath:(NSString *)path;

@end
