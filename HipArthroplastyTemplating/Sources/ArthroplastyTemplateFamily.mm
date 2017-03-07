//
//  ArthroplastyTemplateFamily.m
//  HipArthroplastyTemplating
//  Created by Alessandro Volz on 6/4/09.
//  Copyright 2007-2016 OsiriX Team
//  Copyright 2017 volz.io
//

#import "ArthroplastyTemplateFamily.h"
#import "ArthroplastyTemplate.h"
#import <cmath>


@implementation ArthroplastyTemplateFamily

@synthesize templates = _templates;

-(id)initWithTemplate:(ArthroplastyTemplate*)templat {
	self = [super init];
	
	_templates = [[NSMutableArray arrayWithCapacity:8] retain];
	[self add:templat];
	
	return self;
}

-(NSArray*)templates {
    return [_templates sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSString* n1 = [(ArthroplastyTemplate*)obj1 size];
        NSString* n2 = [(ArthroplastyTemplate*)obj2 size];
        unichar c10 = [n1 characterAtIndex:0];
        if (c10 >= '0' && c10 <= '9' && [n1 floatValue] == [n2 floatValue]) {
            if (n1.length > n2.length)
                return NSOrderedAscending;
            return NSOrderedDescending;
        }
        return [n1 compare:n2 options:NSNumericSearch|NSLiteralSearch];
    }];
}

-(void)dealloc {
	[_templates release]; _templates = NULL;
	[super dealloc];
}

-(BOOL)matches:(ArthroplastyTemplate*)templat {
	if (![[templat manufacturer] isEqualToString:[self manufacturer]]) return NO;
	if (![[templat name] isEqualToString:[self name]]) return NO;
	return YES;
}

-(void)add:(ArthroplastyTemplate*)templat {
	[_templates addObject:templat];
	[templat setFamily:self];
}

+(CGFloat)numberForSize:(NSString*)size {
    NSRange r = [size rangeOfCharacterFromSet:[NSCharacterSet.decimalDigitCharacterSet invertedSet]];
    if (r.location == 0)
        return 0;
    if (r.location != NSNotFound)
        size = [size substringToIndex:r.location];
    return [size floatValue];
}

-(ArthroplastyTemplate*)templateMatchingSize:(NSString*)size side:(ATSide)side {
    // 1) by compairing strings
    for (ArthroplastyTemplate* at in _templates)
        if ([at.size isEqualToString:size] && (at.allowedSides&side) == side)
            return at;
    
    // 2) by compairing numbers...
    NSInteger closestIndex = -1;
    CGFloat closestDelta;
    CGFloat nin = [[self class] numberForSize:size];
    for (NSInteger i = 0; i < _templates.count; ++i) {
        ArthroplastyTemplate* at = [_templates objectAtIndex:i];
        if ((at.allowedSides&side) == side) {
            CGFloat nat = [[self class] numberForSize:at.size];
            if (nin == nat)
                return at;
            
            CGFloat delta = std::pow(nat-nin, 2); // actially this is delta pow 2, but we don't need the actual value so avoid sqrt to save time
            
            if (closestIndex == -1 || closestDelta > delta) {
                closestIndex = i;
                closestDelta = delta;
            }
        }
    }
    
    if (closestIndex != -1)
        return [_templates objectAtIndex:closestIndex];
    
    return nil;
}

-(ArthroplastyTemplate*)templateForIndex:(NSInteger)index {
	return [self.templates objectAtIndex:index];
}

-(ArthroplastyTemplate*)templateAfter:(ArthroplastyTemplate*)t {
    NSArray* ts = [self.templates filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"patientSide = %@", t.patientSide]];
	return [ts objectAtIndex:([ts indexOfObject:t]+1)%[ts count]];
}

-(ArthroplastyTemplate*)templateBefore:(ArthroplastyTemplate*)t {
    NSArray* ts = [self.templates filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"patientSide = %@", t.patientSide]];
    NSUInteger index = [ts indexOfObject:t];
	if (index == 0) index = [ts count]-1;
    else --index;
	return [ts objectAtIndex:index];
}

-(NSString*)fixation {
	return [self templatesValueForKey:@"fixation"];
}

-(NSString*)group {
	return [self templatesValueForKey:@"group"];
}

-(NSString*)manufacturer {
	return [self templatesValueForKey:@"manufacturer"];
}

-(NSString*)modularity {
	return [self templatesValueForKey:@"modularity"];
}

-(NSString*)name {
	return [self templatesValueForKey:@"name"];
}

-(NSString*)patientSide {
	return [self templatesValueForKey:@"patientSide"];
}

-(NSString*)surgery {
	return [self templatesValueForKey:@"surgery"];
}

-(NSString*)type {
	return [self templatesValueForKey:@"type"];
}

-(NSString*)templatesValueForKey:(NSString*)key {
    NSArray* distinctValues = [_templates valueForKeyPath:[@"@distinctUnionOfObjects" stringByAppendingPathExtension:key]];
    
    NSMutableArray* values = [NSMutableArray array];
    
    for (NSString* distinctValue in distinctValues)
        if ([distinctValue isKindOfClass:[NSString class]])
            for (NSString *value in [distinctValue componentsSeparatedByString:@"|"])
                if (![values containsObject:value])
                    [values addObject:value];
    
    return [values componentsJoinedByString:@"|"];
}

@end
