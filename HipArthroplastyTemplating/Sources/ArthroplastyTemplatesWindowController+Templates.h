//
//  ArthroplastyTemplatesWindowController+List.h
//  HipArthroplastyTemplating
//  Created by Alessandro Volz on 08.09.09.
//  Copyright 2007-2016 OsiriX Team
//  Copyright 2017 volz.io
//

#import "ArthroplastyTemplatesWindowController.h"


@interface ArthroplastyTemplatesWindowController (Templates)

- (void)initTemplates;
- (void)awakeTemplates;
- (void)deallocTemplates;

- (ArthroplastyTemplate *)templateAtPath:(NSString *)path;
- (ArthroplastyTemplateFamily *)familyAtIndex:(NSInteger)index;
- (IBAction)filterAction:(id)sender;
- (BOOL)setFilter:(NSString *)string;

@end
