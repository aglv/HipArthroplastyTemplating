//
//  ArthroplastyTemplateFamily.h
//  HipArthroplastyTemplating
//  Created by Alessandro Volz on 6/4/09.
//  Copyright 2007-2016 OsiriX Team
//  Copyright 2017 volz.io
//

#import <Cocoa/Cocoa.h>
#import "ArthroplastyTemplate.h"

@interface ArthroplastyTemplateFamily : NSObject {
	NSMutableArray<ArthroplastyTemplate *> *_templates;
}

@property (readonly) NSArray<ArthroplastyTemplate *> *templates;
@property (readonly) NSString *fixation, *group, *manufacturer, *modularity, *name, *patientSide, *surgery, *type;

- (id)initWithTemplate:(ArthroplastyTemplate *)templat;
- (BOOL)matches:(ArthroplastyTemplate *)templat;
- (void)add:(ArthroplastyTemplate *)templat;
- (ArthroplastyTemplate *)templateMatchingOffset:(NSString *)offset size:(NSString *)size side:(ArthroplastyTemplateSide)side;

- (ArthroplastyTemplate *)templateAfter:(ArthroplastyTemplate *)t;
- (ArthroplastyTemplate *)templateBefore:(ArthroplastyTemplate *)t;

+ (CGFloat)numberForString:(NSString *)size;

@end
