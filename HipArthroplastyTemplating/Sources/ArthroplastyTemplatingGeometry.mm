//
//  ArthroplastyTemplatingGeometry.m
//  HipArthroplastyTemplating
//  Created by Alessandro Volz on 28.06.12.
//  Copyright 2007-2016 OsiriX Team
//  Copyright 2017 volz.io
//

#import "ArthroplastyTemplatingGeometry.h"
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
#import <OsiriXAPI/DCMPix.h>
#pragma clang diagnostic pop
#include <cmath>

@implementation ArthroplastyTemplatingPoint

@synthesize x = _x, y = _y;

+ (id)pointWith:(NSInteger)x :(NSInteger)y {
    return [[[[self class] alloc] initWithX:x y:y] autorelease];
}

+ (id)pointWithX:(NSInteger)x y:(NSInteger)y {
    return [[[[self class] alloc] initWithX:x y:y] autorelease];
}

- (id)initWithX:(NSInteger)x y:(NSInteger)y {
    if ((self = [super init])) {
        _x = x; 
        _y = y;
    }
    
    return self;
}

- (BOOL)isEqual:(ArthroplastyTemplatingPoint *)other {
    return [other isKindOfClass:[ArthroplastyTemplatingPoint class]] && _x == other.x && _y == other.y;
}

- (NSArray *)neighbors {
    return [NSArray arrayWithObjects:
            [ArthroplastyTemplatingPoint pointWith:_x:_y-1],
            [ArthroplastyTemplatingPoint pointWith:_x+1:_y],
            [ArthroplastyTemplatingPoint pointWith:_x:_y+1],
            [ArthroplastyTemplatingPoint pointWith:_x-1:_y],
            nil];
}

/*-(CGFloat)distanceTo:(ArthroplastyTemplatingPoint *)p {
    return std::sqrt(std::pow((CGFloat)_x-p.x, 2)+std::pow((CGFloat)_y-p.y, 2));
}*/

- (CGFloat)distanceToNoSqrt:(ArthroplastyTemplatingPoint *)p {
    return std::pow((CGFloat)_x-p.x, 2)+std::pow((CGFloat)_y-p.y, 2);
}

- (NSString *)description {
    return [NSString stringWithFormat:@"[%d,%d]", (int)_x, (int)_y];
}

- (NSPoint)NSPoint {
    return NSMakePoint(_x, _y);
}

@end

@implementation ArthroplastyTemplatingGeometry

+ (BOOL)growRegionFromPoint:(ArthroplastyTemplatingPoint *)p0 onDCMPix:(DCMPix *)pix outputPoints:(NSMutableArray *)points outputContour:(NSMutableArray *)contour {
    NSThread *thread = [NSThread currentThread];
    
    const NSInteger w = pix.pwidth, h = pix.pheight, wh = w*h;
    float *data = pix.fImage;
    
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

    float threshold = (data(p0)+mean)/2 - fabs(max-min)/20;
    
    uint8 *mask = (uint8 *)[[NSMutableData dataWithLength:sizeof(uint8)*w*h] mutableBytes];
    NSMutableArray *toBeVisited = [NSMutableArray arrayWithObject:p0];
    mask(p0) = 1;
    
    while (toBeVisited.count && !thread.isCancelled) {
        ArthroplastyTemplatingPoint *p = [toBeVisited lastObject];
        [toBeVisited removeLastObject];
        [points addObject:p];
        for (ArthroplastyTemplatingPoint *t in p.neighbors)
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

+ (NSArray<ArthroplastyTemplatingPoint *> *)mostDistantPairOfPointsInArray:(NSArray<ArthroplastyTemplatingPoint *> *)points {
    if (points.count < 2)
        return nil;

    NSThread *thread = [NSThread currentThread];

    NSUInteger p1i = 0, p2i = 0;
    CGFloat rd = 0;
    
    NSUInteger ilimit = points.count-2, jlimit = points.count-1;
    for (NSUInteger i = 0; i < ilimit; ++i)
        for (NSUInteger j = i+1; j <= jlimit; ++j) {
            if (thread.isCancelled)
                return nil;
            CGFloat ijd = [points[i] distanceToNoSqrt:points[j]];
            if (ijd > rd) {
                rd = ijd; p1i = i; p2i = j;
            }
        }
    
    return @[ points[p1i], points[p2i] ];
}

@end
