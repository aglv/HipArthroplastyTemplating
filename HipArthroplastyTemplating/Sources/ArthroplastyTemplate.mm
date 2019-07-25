//
//  ArthroplastyTemplate.m
//  HipArthroplastyTemplating
//  Created by Joris Heuberger on 04/04/07.
//  Copyright 2007-2016 OsiriX Team
//  Copyright 2017 volz.io
//

#import "ArthroplastyTemplate.h"

@implementation ArthroplastyTemplate

@synthesize family = _family;
@synthesize path = _path;

- (id)initWithPath:(NSString *)path {
	if (!(self = [super init]))
        return nil;
    
	_path = [path retain];
	
    return self;
}

- (void)dealloc {
	[_path release];
    
	[super dealloc];
}

- (NSString *)fixation {
	[NSException raise:NSInternalInconsistencyException format:@"[ArthroplastyTemplate fixation] must be implemented"];
	return nil;
}

- (NSString *)group {
	[NSException raise:NSInternalInconsistencyException format:@"[ArthroplastyTemplate group] must be implemented"];
	return nil;
}

- (NSString *)manufacturer {
	[NSException raise:NSInternalInconsistencyException format:@"[ArthroplastyTemplate manufacturer] must be implemented"];
	return nil;
}

- (NSString *)modularity {
	[NSException raise:NSInternalInconsistencyException format:@"[ArthroplastyTemplate modularity] must be implemented"];
	return nil;
}

- (NSString *)name {
	[NSException raise:NSInternalInconsistencyException format:@"[ArthroplastyTemplate name] must be implemented"];
	return nil;
}

- (NSString *)patientSide {
	[NSException raise:NSInternalInconsistencyException format:@"[ArthroplastyTemplate patientSide] must be implemented"];
	return nil;
}

- (NSString *)surgery {
	[NSException raise:NSInternalInconsistencyException format:@"[ArthroplastyTemplate surgery] must be implemented"];
	return nil;
}

- (NSString *)type {
	[NSException raise:NSInternalInconsistencyException format:@"[ArthroplastyTemplate type] must be implemented"];
	return nil;
}

- (NSString *)size {
    [NSException raise:NSInternalInconsistencyException format:@"[ArthroplastyTemplate size] must be implemented"];
    return nil;
}

- (NSString *)offset {
    [NSException raise:NSInternalInconsistencyException format:@"[ArthroplastyTemplate offset] must be implemented"];
    return nil;
}

- (NSString *)referenceNumber {
	[NSException raise:NSInternalInconsistencyException format:@"[ArthroplastyTemplate referenceNumber] must be implemented"];
	return nil;
}

- (CGFloat)scale {
	[NSException raise:NSInternalInconsistencyException format:@"[ArthroplastyTemplate scale] must be implemented"];
	return 0;
}

- (CGFloat)rotation { // in RADS
	[NSException raise:NSInternalInconsistencyException format:@"[ArthroplastyTemplate rotation] must be implemented"];
	return 0;
}

- (NSString *)referenceNumberForOtherPatientSide {
    return nil;
}

- (ArthroplastyTemplate *)templateForOtherPatientSide {
    return nil;
}

- (ArthroplastyTemplateSide)side {
	return ArthroplastyTemplateRightSide;
}

@end
