//
//  HipAT2D.h
//  HipArthroplastyTemplating
//  Created by Alessandro Volz on 28.06.12.
//  Copyright 2007-2016 OsiriX Team
//  Copyright 2016 volz.io
//

#import <Foundation/Foundation.h>

@interface HipAT2DIntegerPoint : NSObject {
    NSInteger _x, _y;
}

@property NSInteger x;
@property NSInteger y;

+(id)pointWith:(NSInteger)x :(NSInteger)y;
+(id)pointWithX:(NSInteger)x y:(NSInteger)y;
-(id)initWithX:(NSInteger)x y:(NSInteger)y;

-(NSPoint)nsPoint;

@end

@class DCMPix;

@interface HipAT2D : NSObject

+ (BOOL)growRegionFromPoint:(HipAT2DIntegerPoint*)p0 onDCMPix:(DCMPix*)pix outputPoints:(NSMutableArray*)points outputContour:(NSMutableArray*)contour;
+ (NSArray*)mostDistantPairOfPointsInArray:(NSArray*)points;

@end