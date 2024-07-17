//
//  ArthroplastyTemplate.h
//  HipArthroplastyTemplating
//  Created by Joris Heuberger on 04/04/07.
//  Copyright 2007-2016 OsiriX Team
//  Copyright 2017 volz.io
//

#import <Cocoa/Cocoa.h>
@class ArthroplastyTemplateFamily;

typedef NS_ENUM(NSUInteger, ArthroplastyTemplateProjection) {
    ArthroplastyTemplateAnteriorPosteriorProjection = 0,
    ArthroplastyTemplateMedialLateralProjection = 1
};
//typedef enum {
//    ArthroplastyTemplateAnteriorPosteriorDirection = 0,
//    ArthroplastyTemplateLateralDirection
//} ArthroplastyTemplateViewDirection;

typedef NS_OPTIONS(NSUInteger, ArthroplastyTemplateSide) {
    ArthroplastyTemplateRightSide = 0x01,
    ArthroplastyTemplateLeftSide = 0x02,
    ArthroplastyTemplateBothSides = ArthroplastyTemplateRightSide|ArthroplastyTemplateLeftSide
};
//typedef int ATSide;
//#define ATRightSideMask 1
//#define ATLeftSideMask 2
//#define ATBothSidesMask 3

@interface ArthroplastyTemplate : NSObject {
	NSURL *_fileURL;
	ArthroplastyTemplateFamily *_family;
}

@property (readonly) NSURL *fileURL;
@property (assign) ArthroplastyTemplateFamily *family;
@property (readonly) NSString *fixation, *group, *manufacturer, *modularity, *name, *patientSide, *surgery, *type, *size, *offset, *referenceNumber, *innerDiameter;
@property (readonly) CGFloat scale, rotation;
@property (readonly) ArthroplastyTemplateSide side;

- (instancetype)initWithFileURL:(NSURL *)fileURL;

@end

@interface ArthroplastyTemplate (Abstract)

+ (NSArray *)templatesFromFileURL:(NSURL *)fileURL;

- (NSURL *)pdfURLForProjection:(ArthroplastyTemplateProjection)projection;
- (BOOL)origin:(NSPoint *)point forProjection:(ArthroplastyTemplateProjection)projection;
- (BOOL)stemDistalToProximalComp:(NSPoint *)point forProjection:(ArthroplastyTemplateProjection)projection;
- (NSArray *)textualData;
- (NSArray *)headRotationPointsForProjection:(ArthroplastyTemplateProjection)projection;
//- (NSArray *)matingPointsForProjection:(ArthroplastyTemplateProjection)projection;

- (BOOL)isProximal;
- (BOOL)isDistal;

- (ArthroplastyTemplateSide)allowedSides;

- (NSString *)referenceNumberForOtherPatientSide;
- (ArthroplastyTemplate *)templateForOtherPatientSide;

@end
