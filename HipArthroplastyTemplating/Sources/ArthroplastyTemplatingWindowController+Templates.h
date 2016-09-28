//
//  ArthroplastyTemplatingWindowController+List.h
//  HipArthroplastyTemplating
//  Created by Alessandro Volz on 08.09.09.
//  Copyright 2007-2016 OsiriX Team
//  Copyright 2016 volz.io
//

#import "ArthroplastyTemplatingWindowController.h"

@interface ArthroplastyTemplatingWindowController (Templates)

-(void)awakeTemplates;
-(ArthroplastyTemplate*)templateAtPath:(NSString*)path;
-(ArthroplastyTemplate*)currentTemplate;
-(ArthroplastyTemplateFamily*)familyAtIndex:(NSInteger)index;
-(ArthroplastyTemplateFamily*)selectedFamily;
-(IBAction)searchFilterChanged:(id)sender;
-(BOOL)setFilter:(NSString*)string;

@end
