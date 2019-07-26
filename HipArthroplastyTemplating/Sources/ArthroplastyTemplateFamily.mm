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

- (id)initWithTemplate:(ArthroplastyTemplate *)templat {
	if (!(self = [super init]))
        return nil;
	
	_templates = [[NSMutableArray arrayWithCapacity:8] retain];
	[self add:templat];
	
	return self;
}

- (NSArray *)templates {
    return [_templates sortedArrayUsingComparator:^NSComparisonResult(ArthroplastyTemplate *t1, ArthroplastyTemplate *t2) {
        NSString *o1 = t1.offset, *o2 = t2.offset;
        
        if (o1 && o2) {
            NSComparisonResult cr = [o1 compare:o2 options:NSNumericSearch|NSLiteralSearch];
            if (cr != NSOrderedSame)
                return cr;
        }
        else if (o1)
            return NSOrderedDescending;
        else if (o2)
            return NSOrderedAscending;
        
        NSString *s1 = [t1 size], *s2 = [t2 size];
        
        unichar c10 = [s1 characterAtIndex:0];
        if (c10 >= '0' && c10 <= '9' && [s1 floatValue] == [s2 floatValue]) { // same numeric value, sort '00' before '0'
            if (s1.length > s2.length)
                return NSOrderedAscending;
            if (s1.length < s2.length)
                return NSOrderedDescending;
            return NSOrderedSame;
        }
        
        return [s1 compare:s2 options:NSNumericSearch|NSLiteralSearch|NSCaseInsensitiveSearch];
    }];
}

- (void)dealloc {
	[_templates release]; _templates = NULL;
	[super dealloc];
}

- (BOOL)matches:(ArthroplastyTemplate *)templat {
	if (![[templat manufacturer] isEqualToString:[self manufacturer]]) return NO;
	if (![[templat name] isEqualToString:[self name]]) return NO;
	return YES;
}

- (void)add:(ArthroplastyTemplate *)templat {
	[_templates addObject:templat];
	[templat setFamily:self];
}

+ (CGFloat)numberForString:(NSString *)str {
    if (!str)
        return 0;
    NSRange r = [str rangeOfCharacterFromSet:[NSCharacterSet.decimalDigitCharacterSet invertedSet]];
    if (r.location == 0)
        return 0;
    if (r.location != NSNotFound)
        str = [str substringToIndex:r.location];
    return [str floatValue];
}

- (ArthroplastyTemplate *)templateMatchingOffset:(NSString *)offset size:(NSString *)size side:(ArthroplastyTemplateSide)side {
    // 1) by compairing strings
    for (ArthroplastyTemplate *t in _templates) {
        if ((t.offset == offset || [t.offset isEqualToString:offset]) && (t.size == size || [t.size isEqualToString:size]) && (t.allowedSides&side) == side)
            return t;
    }
    
    // 2) by compairing numbers...
    
    CGFloat noffset = [self.class numberForString:offset];
    CGFloat nsize = [self.class numberForString:size];
    
    NSInteger closestIndex = -1;
    CGFloat closestDelta;
    for (NSInteger i = 0; i < _templates.count; ++i) {
        ArthroplastyTemplate *at = [_templates objectAtIndex:i];
        if ((at.allowedSides&side) == side) {
            CGFloat atnsize = [self.class numberForString:at.size];
            CGFloat atnoffset = [self.class numberForString:at.offset];
            if (nsize == atnsize)
                if (noffset == atnoffset)
                    return at;
            
            CGFloat delta = std::pow(atnsize-nsize, 2); // actually this is delta pow 2, but we don't need the actual value so avoid sqrt to save time
            
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

- (ArthroplastyTemplate *)templateForIndex:(NSInteger)index {
	return [self.templates objectAtIndex:index];
}

- (ArthroplastyTemplate *)templateAfter:(ArthroplastyTemplate *)t {
    NSArray *ts = [self.templates filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"patientSide = %@", t.patientSide]];
	
    NSUInteger index = [ts indexOfObject:t];
    if (index == ts.count-1)
        return nil;
    
    return ts[index+1];
}

- (ArthroplastyTemplate *)templateBefore:(ArthroplastyTemplate *)t {
    NSArray *ts = [self.templates filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"patientSide = %@", t.patientSide]];
    
    NSUInteger index = [ts indexOfObject:t];
	if (index == 0)
        return nil;
    
	return ts[index-1];
}

//- (BOOL)hasOffsets {
//    if (_hasOffsets)
//        return _hasOffsets.boolValue;
//
//    BOOL hasOffsets = NO;
//    for (ArthroplastyTemplate *templat in self.templates)
//        if (templat.offset.length) {
//            hasOffsets = YES;
//            break;
//        }
//
//    _hasOffsets = [@(hasOffsets) retain];
//
//    return hasOffsets;
//}

- (NSString *)fixation {
	return [self templatesValueForKey:@"fixation"];
}

- (NSString *)group {
	return [self templatesValueForKey:@"group"];
}

- (NSString *)manufacturer {
	return [self templatesValueForKey:@"manufacturer"];
}

- (NSString *)modularity {
	return [self templatesValueForKey:@"modularity"];
}

- (NSString *)name {
	return [self templatesValueForKey:@"name"];
}

- (NSString *)patientSide {
	return [self templatesValueForKey:@"patientSide"];
}

- (NSString *)surgery {
	return [self templatesValueForKey:@"surgery"];
}

- (NSString *)type {
	return [self templatesValueForKey:@"type"];
}

- (NSString *)templatesValueForKey:(NSString *)key {
    NSArray *distinctValues = [_templates valueForKeyPath:[@"@distinctUnionOfObjects" stringByAppendingPathExtension:key]];
    
    NSMutableArray *values = [NSMutableArray array];
    
    for (NSString *distinctValue in distinctValues)
        if ([distinctValue isKindOfClass:[NSString class]])
            for (NSString *value in [distinctValue componentsSeparatedByString:@"|"])
                if (![values containsObject:value])
                    [values addObject:value];
    
    return [values componentsJoinedByString:@"|"];
}

@end
