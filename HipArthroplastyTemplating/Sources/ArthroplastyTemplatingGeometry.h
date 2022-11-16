//
//  ArthroplastyTemplatingGeometry.h
//  HipArthroplastyTemplating
//  Created by Alessandro Volz on 28.06.12.
//  Copyright 2007-2016 OsiriX Team
//  Copyright 2017 volz.io
//

#import <Foundation/Foundation.h>

@interface ArthroplastyTemplatingPoint : NSObject {
    NSInteger _x, _y;
}

@property NSInteger x;
@property NSInteger y;

+ (id)pointWith:(NSInteger)x :(NSInteger)y;
+ (id)pointWithX:(NSInteger)x y:(NSInteger)y;
- (id)initWithX:(NSInteger)x y:(NSInteger)y;

- (NSPoint)NSPoint;

@end

@class DCMPix;

@interface ArthroplastyTemplatingGeometry : NSObject

+ (BOOL)growRegionFromPoint:(ArthroplastyTemplatingPoint *)p0 onDCMPix:(DCMPix *)pix outputPoints:(NSMutableArray<ArthroplastyTemplatingPoint *> *)points outputContour:(NSMutableArray<ArthroplastyTemplatingPoint *> *)contour;
+ (NSArray<ArthroplastyTemplatingPoint *> *)mostDistantPairOfPointsInArray:(NSArray<ArthroplastyTemplatingPoint *> *)points;

@end
