//
//  InfoTxtArthroplastyTemplate.m
//  HipArthroplastyTemplating
//  Created by Joris Heuberger on 19/03/07.
//  Copyright 2007-2016 OsiriX Team
//  Copyright 2017 volz.io
//

#import "InfoTxtArthroplastyTemplate.h"
#import "ArthroplastyTemplateFamily.h"
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
#import <OsiriXAPI/NSString+N2.h>
#import <OsiriXAPI/N2Operators.h>
#pragma clang diagnostic pop

@implementation InfoTxtArthroplastyTemplate

static id First(id a, id b) {
	return a? a : b;
}

+ (NSArray *)templatesFromFileAtPath:(NSString *)path {
    return @[ [[[[self class] alloc] initFromFileAtPath:path] autorelease] ];
}

+ (NSDictionary *)propertiesFromInfoFileAtPath:(NSString *)path {
	NSError *error;
	NSString *fileContent = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
	if (!fileContent) {
		fileContent = [NSString stringWithContentsOfFile:path encoding:NSISOLatin1StringEncoding error:&error];
		if (!fileContent) {
			NSLog(@"[InfoTxtArthroplastyTemplate propertiesFromFileInfoAtPath]: %@", error);
			return NULL;
		}
	}
	
	NSScanner *infoFileScanner = [NSScanner scannerWithString:fileContent];
	[infoFileScanner setCharactersToBeSkipped:[NSCharacterSet whitespaceCharacterSet]];
	
	NSMutableDictionary *properties = [[[NSMutableDictionary alloc] initWithCapacity:128] autorelease];
	NSCharacterSet *newlineCharacterSet = [NSCharacterSet newlineCharacterSet];
	while (![infoFileScanner isAtEnd]) {
		NSString *key = @"", *value = @"";
		
        [infoFileScanner scanUpToString:@":=:" intoString:&key];
		
        key = [key stringByTrimmingStartAndEnd];
		
        [infoFileScanner scanString:@":=:" intoString:NULL];
		
        [infoFileScanner scanUpToCharactersFromSet:newlineCharacterSet intoString:&value];
		value = [value stringByTrimmingStartAndEnd];
        if ([value isEqualToString:@"†"])
            value = @"";
        
        if (value.length)
            [properties setObject:value forKey:key];
        
		[infoFileScanner scanCharactersFromSet:newlineCharacterSet intoString:NULL];
	}
	
	return properties;
}

- (instancetype)initFromFileAtPath:(NSString *)path {
    NSDictionary *properties = [[self class] propertiesFromInfoFileAtPath:path];
    if (!properties)
        return nil;
    
	if (!(self = [super initWithPath:path]))
        return nil;
	
    _properties = [properties retain];
	
	return self;
}

- (void)dealloc {
	[_properties release]; _properties = nil;
	[super dealloc];
}

- (NSString *)pdfPathForProjection:(ArthroplastyTemplateProjection)projection {
	NSString *key = (projection == ArthroplastyTemplateAnteriorPosteriorProjection)? @"PDF_FILE_AP" : @"PDF_FILE_ML";
	NSString *filename = [_properties objectForKey:key];
    if (!filename)
        return nil;
	return [[_path stringByDeletingLastPathComponent] stringByAppendingPathComponent:filename];
}

- (NSString *)prefixForProjection:(ArthroplastyTemplateProjection)projection {
	return (projection == ArthroplastyTemplateAnteriorPosteriorProjection)? @"AP" : @"ML";
}

- (BOOL)point:(NSPoint *)point forEntry:(NSString *)entry projection:(ArthroplastyTemplateProjection)projection {
	NSString *prefix = [NSString stringWithFormat:@"%@_%@_", [self prefixForProjection:projection], entry];
	
	NSString *key = [NSString stringWithFormat:@"%@X", prefix];
	NSString *xs = [_properties objectForKey:key];
	key = [NSString stringWithFormat:@"%@Y", prefix];
	NSString *ys = [_properties objectForKey:key];
	
	if (!xs || !ys || ![xs length] || ![ys length])
		return NO;
	
	*point = NSMakePoint([xs floatValue], [ys floatValue])/25.4; // 1in = 25.4mm, ORIGIN data in mm
	return YES;
}

- (BOOL)origin:(NSPoint *)point forProjection:(ArthroplastyTemplateProjection)projection {
	return [self point:point forEntry:@"ORIGIN" projection:projection];
}

//- (BOOL)csys:(NSPoint *)point forProjection:(ArthroplastyTemplateProjection)projection {
//    return [self point:point forEntry:@"PRODUCT_FAMILY_CSYS" projection:projection];
//}

- (BOOL)stemDistalToProximalComp:(NSPoint *)point forProjection:(ArthroplastyTemplateProjection)projection {
    if (![self point:point forEntry:@"STEM_DISTAL_TO_PROXIMAL_COMP" projection:projection])
        return NO;
    
    NSPoint origin = NSZeroPoint;
    if ([self origin:&origin forProjection:projection])
        *point += origin;
    
    return YES;
}

- (NSArray<NSValue *> *)headRotationPointsForProjection:(ArthroplastyTemplateProjection)projection {
	NSMutableArray<NSValue *> *points = [NSMutableArray arrayWithCapacity:5];
	
	NSPoint origin; [self origin:&origin forProjection:projection];
//	NSPoint csys; BOOL hasCsys = [self csys:&csys forProjection:projection];
    
	for (unsigned i = 1; i <= 5; ++i) {
		NSPoint point = {0,0};
        
        BOOL hasPoint = [self point:&point forEntry:[NSString stringWithFormat:@"HEAD_ROTATION_POINT_%d", i] projection:projection];
        if (hasPoint)
/*           if (hasCsys)
                point = (point+csys);
            else*/ point += origin;
        
		[points addObject:[NSValue valueWithPoint:point]];
	}
	
	return points;
}

//- (NSArray<NSValue *> *)matingPointsForProjection:(ArthroplastyTemplateProjection)projection {
//	NSMutableArray<NSValue *> *points = [NSMutableArray arrayWithCapacity:5];
//
//	NSPoint origin; [self origin:&origin forProjection:projection];
//
//	for (unsigned i = 0; i < 4; ++i) {
//		NSString *ki = NULL;
//		switch (i) {
//			case 0: ki = @"A"; break;
//			case 1: ki = @"A2"; break;
//			case 2: ki = @"B"; break;
//			case 3: ki = @"B2"; break;
//		}
//
//		NSPoint point = {0,0};
//
//        BOOL hasPoint = [self point:&point forEntry:[NSString stringWithFormat:@"MATING_POINT_%@", ki] projection:projection];
//        if (hasPoint)
//            point += origin;
//
//		[points addObject:[NSValue valueWithPoint:point]];
//	}
//
//	return points;
//}

- (NSArray *)textualData {
    NSString *dimInfo = nil;
    if (!self.offset)
        dimInfo = [NSString stringWithFormat:@"Size: %@", self.size];
    else dimInfo = [NSString stringWithFormat:@"Offset/Size: %@/%@", self.offset, self.size];

    return [NSArray arrayWithObjects: self.name, dimInfo, self.manufacturer, @"", @"", NULL];
}

// props

- (NSString *)fixation {
	return [_properties objectForKey:@"FIXATION_TYPE"];
}

- (NSString *)group {
	return [_properties objectForKey:@"PRODUCT_GROUP"];
}

- (NSString *)manufacturer {
	return First([_properties objectForKey:@"IMPLANT_MANUFACTURER"], [_properties objectForKey:@"DESIGN_OWNERSHIP"]);
}

- (NSString *)modularity {
	return [_properties objectForKey:@"MODULARITY_INFO"];
}

- (NSString *)name {
	return First([_properties objectForKey:@"COMPONENT_FAMILY_NAME"], [_properties objectForKey:@"PRODUCT_FAMILY_NAME"]);
}

- (NSString *)patientSide {
	return First([_properties objectForKey:@"PATIENT_SIDE"], [_properties objectForKey:@"LEFT_RIGHT"]);
}

- (ArthroplastyTemplateSide)allowedSides {
	NSString* patientSide = [[self patientSide] lowercaseString];
    ArthroplastyTemplateSide r = 0;
    if ([patientSide contains:@"left"])
        r |= ArthroplastyTemplateLeftSide;
    if ([patientSide contains:@"right"])
        r |= ArthroplastyTemplateRightSide;
    if (r)
        return r;
    return ArthroplastyTemplateBothSides;
}

- (NSString *)surgery {
	return [_properties objectForKey:@"TYPE_OF_SURGERY"];
}

- (NSString *)type {
	return [_properties objectForKey:@"COMPONENT_TYPE"];
}

- (NSString *)size {
    return [_properties objectForKey:@"SIZE"];
}

- (NSString *)catalogDimension:(NSString *)key {
    for (NSString *pair in [_properties[@"CATALOG_DIMENSIONS"] componentsSeparatedByString:@";"]) {
        NSArray<NSString *> *keyval = [pair.stringByTrimmingStartAndEnd componentsSeparatedByString:@"="];
        if ([keyval[0] isEqualToString:key])
            return keyval[1];
    }
    
    return nil;
}

- (NSString *)innerDiameter {
    return [self catalogDimension:@"Inner Diameter"];
}

- (NSString *)offset {
    return [_properties objectForKey:@"OFFSET"];
}

- (NSString *)referenceNumber {
	return First([_properties objectForKey:@"PRODUCT_ID"], [_properties objectForKey:@"REF_NO"]);
}

- (CGFloat)scale {
    NSString *scale = [_properties objectForKey:@"SCALE"];
    return scale.length? [scale floatValue] : 1;
}

- (CGFloat)rotation {
	NSString *rotationString = [_properties objectForKey:@"AP_HEAD_ROTATION_RADS"];
	return rotationString? [rotationString floatValue] : 0;
}

- (ArthroplastyTemplateSide)side {
	NSString *orientation = [_properties objectForKey:@"ORIENTATION"];
	if (orientation && [orientation compare:@"left" options:NSCaseInsensitiveSearch+NSLiteralSearch] == NSOrderedSame)
		return ArthroplastyTemplateLeftSide;
	return ArthroplastyTemplateRightSide;
}

- (NSString *)referenceNumberForOtherPatientSide {
    return [_properties objectForKey:@"OTHER_SIDE_REF_NO"];
}

- (ArthroplastyTemplate *)templateForOtherPatientSide {
    NSString *otherSideRefNo = [self referenceNumberForOtherPatientSide];
    if (otherSideRefNo.length) {
        NSInteger i = [[self.family.templates valueForKey:@"referenceNumber"] indexOfObject:otherSideRefNo];
        if (i != NSNotFound)
            return [self.family.templates objectAtIndex:i];
    }
    
    // try looking for another template with same COMPONENT_FAMILY_NAME and SIZE and other PATIENT_SIDE
    for (ArthroplastyTemplate *it in self.family.templates)
        if (it != self)
            if ([ArthroplastyTemplateFamily numberForString:it.size] == [ArthroplastyTemplateFamily numberForString:self.size])
                if ([ArthroplastyTemplateFamily numberForString:it.offset] == [ArthroplastyTemplateFamily numberForString:self.offset])
                    if (![it.patientSide isEqualToString:self.patientSide])
                        return it;
    
    return nil;
}

- (BOOL)isProximal {
    return [[self.type lowercaseString] contains:@"proximal"];
}

- (BOOL)isDistal {
    return [[self.type lowercaseString] contains:@"distal"];
}


@end
