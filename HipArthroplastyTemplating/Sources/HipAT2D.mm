//
//  HipAT2D.m
//  HipArthroplastyTemplating
//  Created by Alessandro Volz on 28.06.12.
//  Copyright 2007-2016 OsiriX Team
//  Copyright 2016 volz.io
//

#import "HipAT2D.h"
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
#import <OsiriXAPI/DCMPix.h>
#pragma clang diagnostic pop
#include <cmath>

@implementation HipAT2DIntegerPoint

@synthesize x = _x, y = _y;

+(id)pointWith:(NSInteger)x :(NSInteger)y {
    return [[[[self class] alloc] initWithX:x y:y] autorelease];
}

+(id)pointWithX:(NSInteger)x y:(NSInteger)y {
    return [[[[self class] alloc] initWithX:x y:y] autorelease];
}

-(id)initWithX:(NSInteger)x y:(NSInteger)y {
    if ((self = [super init])) {
        _x = x; 
        _y = y;
    }
    
    return self;
}

-(BOOL)isEqual:(HipAT2DIntegerPoint*)other {
    return [other isKindOfClass:[HipAT2DIntegerPoint class]] && _x == other.x && _y == other.y;
}

-(NSArray*)neighbors {
    return [NSArray arrayWithObjects:
            [HipAT2DIntegerPoint pointWith:_x:_y-1],
            [HipAT2DIntegerPoint pointWith:_x+1:_y],
            [HipAT2DIntegerPoint pointWith:_x:_y+1],
            [HipAT2DIntegerPoint pointWith:_x-1:_y],
            nil];
}

/*-(CGFloat)distanceTo:(HipAT2DIntegerPoint*)p {
    return std::sqrt(std::pow((CGFloat)_x-p.x, 2)+std::pow((CGFloat)_y-p.y, 2));
}*/

-(CGFloat)distanceToNoSqrt:(HipAT2DIntegerPoint*)p {
    return std::pow((CGFloat)_x-p.x, 2)+std::pow((CGFloat)_y-p.y, 2);
}

-(NSString*)description {
    return [NSString stringWithFormat:@"[%d,%d]", (int)_x, (int)_y];
}

-(NSPoint)nsPoint {
    return NSMakePoint(_x, _y);
}

@end

@implementation HipAT2D

+ (BOOL)growRegionFromPoint:(HipAT2DIntegerPoint*)p0 onDCMPix:(DCMPix*)pix outputPoints:(NSMutableArray*)points outputContour:(NSMutableArray*)contour {
    NSThread* thread = [NSThread currentThread];
    
    const NSInteger w = pix.pwidth, h = pix.pheight, wh = w*h;
    float* data = pix.fImage;
    
    float min = FLT_MAX, max = -FLT_MAX, mean = 0;
    for (size_t i = 0; i < wh; ++i) {
        if (thread.isCancelled)
            return NO;
        min = fminf(min, data[i]);
        max = fmaxf(max, data[i]);
        mean += data[i];
    }
    
    mean /= wh;

#define data(p) data[p.x+p.y*w]
#define mask(p) mask[p.x+p.y*w]

    float threshold = mean - fabs(max-min)/20;
    
    uint8* mask = (uint8 *)[[NSMutableData dataWithLength:sizeof(uint8)*w*h] mutableBytes];
    NSMutableArray* toBeVisited = [NSMutableArray arrayWithObject:p0];
    mask(p0) = 1;
    
    while (toBeVisited.count && !thread.isCancelled) {
        HipAT2DIntegerPoint* p = [toBeVisited lastObject];
        [toBeVisited removeLastObject];
        [points addObject:p];
        for (HipAT2DIntegerPoint* t in p.neighbors)
            if (t.x >= 0 && t.y >= 0 && t.x < w && t.y < h && !mask(t)) {
                mask(t) = 1;
                if (data(t) >= threshold)
                    [toBeVisited addObject:t];
                else if (mask(p) != 2) {
                    [contour addObject:p];
                    mask(p) = 2;
                }
            }
    }
    
    return !thread.isCancelled;
}

#undef data
#undef mask

+ (NSArray*)mostDistantPairOfPointsInArray:(NSArray*)points {
    if (points.count < 2)
        return nil;

    NSThread* thread = [NSThread currentThread];

    NSUInteger p1i = 0, p2i = 0;
    CGFloat rd = 0;
    
    NSUInteger ilimit = points.count-2, jlimit = points.count-1;
    for (NSUInteger i = 0; i < ilimit; ++i)
        for (NSUInteger j = i+1; j <= jlimit; ++j) {
            if (thread.isCancelled)
                return nil;
            CGFloat ijd = [[points objectAtIndex:i] distanceToNoSqrt:[points objectAtIndex:j]];
            if (ijd > rd) {
                rd = ijd; p1i = i; p2i = j;
            }
        }
    
    return [NSArray arrayWithObjects: [points objectAtIndex:p1i], [points objectAtIndex:p2i], nil];
}

@end
