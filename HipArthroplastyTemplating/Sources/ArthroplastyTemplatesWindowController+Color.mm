//
//  ArthroplastyTemplatesWindowController+Color.mm
//  HipArthroplastyTemplating
//  Created by Alessandro Volz on 08.09.09.
//  Copyright 2007-2016 OsiriX Team
//  Copyright 2017 volz.io
//

#import "ArthroplastyTemplatesWindowController+Color.h"
#import "ArthroplastyTemplatesWindowController+Private.h"

#import "HipArthroplastyTemplating.h"
#import "ArthroplastyTemplatingUserDefaults.h"

@implementation ArthroplastyTemplatesWindowController (Color)

NSString *ColorifyKey = @"colorify";
NSString *ColorifyColorKey = @"colorify.color";

- (void)awakeColor {
	[_shouldTransformColor setState:[[HipArthroplastyTemplating userDefaults] bool:ColorifyKey otherwise:[_shouldTransformColor state]]];
	[_transformColor setColor:[[HipArthroplastyTemplating userDefaults] color:ColorifyColorKey otherwise:[_transformColor color]]];
}

- (IBAction)transformColorChanged:(id)sender {
	if (sender == _shouldTransformColor) {
		[[HipArthroplastyTemplating userDefaults] setBool:[_shouldTransformColor state] forKey:ColorifyKey];
	} else if (sender == _transformColor) {
		[[HipArthroplastyTemplating userDefaults] setColor:[_transformColor color] forKey:ColorifyColorKey];
	}
}

@end
