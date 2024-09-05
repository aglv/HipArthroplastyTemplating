//
//  ArthroplastyTemplatingStepsController.m
//  HipArthroplastyTemplating
//  Created by Joris Heuberger on 04/04/07.
//  Copyright 2007-2016 OsiriX Team
//  Copyright 2017 volz.io
//

#import "ArthroplastyTemplatingStepsController.h"
#import "ArthroplastyTemplatesWindowController+Templates.h"
#import "HipArthroplastyTemplating.h"
#import "ArthroplastyTemplatingUserDefaults.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
#import <OsiriXAPI/SendController.h>
#import <OsiriXAPI/BrowserController.h>
#import <OsiriXAPI/ViewerController.h>
#import <OsiriXAPI/ROI.h>
#import <OsiriXAPI/DCMPix.h>
#import <OsiriXAPI/DCMView.h>
#import <OsiriXAPI/N2Step.h>
#import <OsiriXAPI/N2Steps.h>
#import <OsiriXAPI/N2StepsView.h>
#import <OsiriXAPI/N2Panel.h>
#import <OsiriXAPI/NSBitmapImageRep+N2.h>
#import <OsiriXAPI/N2Operators.h>
#import <OsiriXAPI/NSThread+N2.h>
#import <OsiriXAPI/ThreadModalForWindowController.h>
#import <OsiriXAPI/Notifications.h>
#import <OsiriXAPI/DicomStudy.h>
#import <OsiriXAPI/N2DisclosureBox.h>
#pragma clang diagnostic pop

#import "ArthroplastyTemplateFamily.h"
#import "ArthroplastyTemplatingGeometry.h"
#include <vector>
#import <objc/runtime.h>

#define kInvalidAngle 666
#define kInvalidMagnification 0
NSString * const PlannersNameUserDefaultKey = @"Planner's Name";

typedef NSInteger ArthroplastyTemplatingLayerReplacementMode NS_TYPED_ENUM;
static ArthroplastyTemplatingLayerReplacementMode const InvalidArthroplastyTemplatingLayerReplacementMode = 0;
static ArthroplastyTemplatingLayerReplacementMode const ArthroplastyTemplatingLayerReplacementModeCup = 1;
static ArthroplastyTemplatingLayerReplacementMode const ArthroplastyTemplatingLayerReplacementModeStem = 2;
static ArthroplastyTemplatingLayerReplacementMode const ArthroplastyTemplatingLayerReplacementModeDistalStem = 3;

@interface ArthroplastyTemplatingStepsController () {
    ArthroplastyTemplatingLayerReplacementMode _replacingMode;
}

- (void)adjustStemToCup:(NSInteger)index;
+ (ArthroplastyTemplatingStepsController *)controllerForROI:(ROI *)roi;

- (ROI *)originalLegInequality;

@end

@interface ROI (HipArthroplastyTemplating)

@end

@implementation ROI (HipArthroplastyTemplating)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        method_exchangeImplementations(class_getInstanceMethod(ROI.class, @selector(valid)), class_getInstanceMethod(ROI.class, @selector(HipArthroplastyTemplating_valid)));
    });
}

- (BOOL)HipArthroplastyTemplating_valid {
    ArthroplastyTemplatingStepsController *controller = [ArthroplastyTemplatingStepsController controllerForROI:self];
    if (controller && self == controller.originalLegInequality)
        return YES;

    return [self HipArthroplastyTemplating_valid];
}

@end

@interface N2DisclosureBox (ArthroplastyTemplating)

@end

@implementation ArthroplastyTemplatingStepsController

@synthesize viewerController = _viewerController;


#pragma mark Initialization

- (id)initWithPlugin:(HipArthroplastyTemplating *)plugin viewerController:(ViewerController *)viewerController {
	if (!(self = [self initWithWindowNibName:@"ArthroplastyTemplatingSteps" owner:self]))
        return nil;
    
	_plugin = [plugin retain];
	_viewerController = [viewerController retain];
	_appliedMagnification = 1;
	
	_knownRois = [[NSMutableSet alloc] initWithCapacity:16];
	
	// place at viewer window upper right corner
	NSRect frame = [[self window] frame];
	NSRect screen = [[[_viewerController window] screen] frame];
	frame.origin.x = screen.origin.x+screen.size.width-frame.size.width;
	frame.origin.y = screen.origin.y+screen.size.height-frame.size.height;
	[[self window] setFrame:frame display:YES];
	
	[_viewerController roiDeleteAll:self];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(observeROIChangedNotification:) name:OsirixROIChangeNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(observeROIRemovedNotification:) name:OsirixRemoveROINotification object:nil];
//	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowWillClose:) name:NSWindowWillCloseNotification object:[self window]];
//	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewerDidChangeKeyStatus:) name:NSWindowDidBecomeKeyNotification object:[_viewerController window]];
//	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewerDidChangeKeyStatus:) name:NSWindowDidResignKeyNotification object:[_viewerController window]];
//	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidChangeKeyStatus:) name:NSWindowDidBecomeKeyNotification object:[self window]];
//	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidChangeKeyStatus:) name:NSWindowDidResignKeyNotification object:[self window]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(observeDatabaseAddNotification:) name:OsirixAddToDBNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(observeViewerWillCloseNotification:) name:OsirixCloseViewerNotification object:nil];
	
	return self;
}

- (void)awakeFromNib {
	[_stepsView setForeColor:[NSColor whiteColor]];
	[_stepsView setControlSize:NSSmallControlSize];

	[_steps addObject: _stepCalibration = [[N2Step alloc] initWithTitle:@"Calibration" enclosedView:_viewCalibration]];
	[_steps addObject: _stepAxes = [[N2Step alloc] initWithTitle:@"Axes" enclosedView:_viewAxes]];
	[_steps addObject: _stepLandmarks = [[N2Step alloc] initWithTitle:@"Femoral landmarks" enclosedView:_viewLandmarks]];
	[_steps addObject: _stepCutting = [[N2Step alloc] initWithTitle:@"Femur identification" enclosedView:_viewCutting]];
	[_steps addObject: _stepCup = [[N2Step alloc] initWithTitle:@"Cup" enclosedView:_viewCup]];
	[_steps addObject: _stepStem = [[N2Step alloc] initWithTitle:@"Stem" enclosedView:_viewStem]];
	[_steps addObject: _stepPlacement = [[N2Step alloc] initWithTitle:@"Reduction" enclosedView:_viewPlacement]];
	[_steps addObject: _stepSave = [[N2Step alloc] initWithTitle:@"Save" enclosedView:_viewSave]];
	[_steps enableDisableSteps];
	
	if ([N2Step instancesRespondToSelector:@selector(setDefaultButton:)]) {
		[_stepCalibration setDefaultButton:doneCalibration];
		[_stepAxes setDefaultButton:doneAxes];
		[_stepLandmarks setDefaultButton:doneLandmarks];
		[_stepCutting setDefaultButton:doneCutting];
		[_stepCup setDefaultButton:doneCup];
		[_stepStem setDefaultButton:doneStem];
		[_stepPlacement setDefaultButton:donePlacement];
		[_stepSave setDefaultButton:doneSave];
	}
	
    for (NSButtonCell *cell in _magnificationRadio.cells)
        [cell setAttributedTitle:[[[NSAttributedString alloc] initWithString:[cell title] attributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSColor whiteColor], NSForegroundColorAttributeName, [cell font], NSFontAttributeName, nil]] autorelease]];
	[_magnificationCustomFactor setBackgroundColor:[self.window backgroundColor]];
    [_magnificationCustomFactor setDrawsBackground:YES];
	[_magnificationCalibrateLength setBackgroundColor:[self.window backgroundColor]];
    [_magnificationCalibrateLength setDrawsBackground:YES];
	[_plannersNameTextField setBackgroundColor:[self.window backgroundColor]];
    [_plannersNameTextField setDrawsBackground:YES];
	[_magnificationCustomFactor setFloatValue:1.15];
    
//	[self updateInfo];
	 
	[_plannersNameTextField setStringValue:[[HipArthroplastyTemplating userDefaults] object:PlannersNameUserDefaultKey otherwise:NSFullUserName()]];
	
	[_steps setCurrentStep:_stepCalibration];
}

- (void)applyMagnification:(CGFloat)magnificationValue {
	CGFloat factor = 1.*_appliedMagnification/magnificationValue;
	
	for (DCMPix *p in [_viewerController pixList]) {
		if (!p.pixelSpacingX && !p.pixelSpacingY) {
			p.pixelSpacingX = p.pixelSpacingY = 1./72;	
			factor *= 720;
			magnificationValue /= 10;
		}
		p.pixelSpacingX *= factor;
		p.pixelSpacingY *= factor;
	}
	
	_appliedMagnification = magnificationValue;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:OsirixRecomputeROINotification object:_viewerController userInfo:nil];
}

- (void)dealloc {
	[self hideTemplatesPanel];
	
	[self resetSBSUpdatingView:NO];
	
	[self applyMagnification:1];
	
	[_stepCalibration release];
	[_stepAxes release];
	[_stepLandmarks release];
	[_stepCutting release];
	[_stepCup release];
	[_stepStem release];
	[_stepPlacement release];
	[_stepSave release];
	[_knownRois release];
	if (_isMyMouse) [_isMyMouse release];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[super dealloc];
}

- (NSString *)windowFrameAutosaveName {
	return @"Arthroplasty Templating";
}

#pragma mark Windows

- (void)windowWillClose:(NSNotification *)note { // this window is closing
    [self autorelease];
}

- (void)observeViewerWillCloseNotification:(NSNotification *)note {
	[self close];
}

- (void)viewerDidChangeKeyStatus:(NSNotification *)note {
	if ([[_viewerController window] isKeyWindow])
		;//[[self window] orderFront:self];
	else { 
		if ([[self window] isKeyWindow]) return; // TODO: somehow this is not yet valid (both windows are not the key window)
		if ([[[_plugin templatesWindowController] window] isKeyWindow]) return;
//		[[self window] orderOut:self];
	}
}

- (void)windowDidChangeKeyStatus:(NSNotification *)notif {
	NSLog(@"windowDidChangeKeyStatus");
}

#pragma mark Link to OsiriX

- (void)populateViewerContextualMenu:(NSMenu *)menu forROI:(ROI *)roi {
    if (!roi)
        return;
    
    NSInteger i = 1; // first item (index 0) is the ROI NAME
    
    if (roi == _cupLayer) {
        [menu insertItem:[NSMenuItem separatorItem] atIndex:i++];
        [menu insertItemWithTitle:[NSString stringWithFormat:NSLocalizedString(@"%@: %@", nil), NSLocalizedString(@"Cup", nil), _cupTemplate.name] action:nil keyEquivalent:@"" atIndex:i++];
        [self insertOtherItemsMenu:menu mode:ArthroplastyTemplatingLayerReplacementModeCup atIndex:&i];
        [menu insertItem:[NSMenuItem separatorItem] atIndex:i++];
    }
    else if (roi == _stemLayer) {
        [menu insertItem:[NSMenuItem separatorItem] atIndex:i++];
        NSString *component = _stemTemplate.isProximal? NSLocalizedString(@"Proximal Body", nil) : NSLocalizedString(@"Stem", nil);
        [menu insertItemWithTitle:[NSString stringWithFormat:NSLocalizedString(@"%@: %@", nil), component, _stemTemplate.name] action:nil keyEquivalent:@"" atIndex:i++];
        [self insertOtherItemsMenu:menu mode:ArthroplastyTemplatingLayerReplacementModeStem atIndex:&i];
        [menu insertItem:[NSMenuItem separatorItem] atIndex:i++];
    }
    else if (roi == _distalStemLayer) {
        [menu insertItem:[NSMenuItem separatorItem] atIndex:i++];
        [menu insertItemWithTitle:[NSString stringWithFormat:NSLocalizedString(@"%@: %@", nil), NSLocalizedString(@"Stem", nil), _distalStemTemplate.name] action:nil keyEquivalent:@"" atIndex:i++];
        [self insertOtherItemsMenu:menu mode:ArthroplastyTemplatingLayerReplacementModeDistalStem atIndex:&i];
        [menu insertItem:[NSMenuItem separatorItem] atIndex:i++];
    }
}

- (void)insertOtherItemsMenu:(NSMenu *)menu mode:(ArthroplastyTemplatingLayerReplacementMode)mode atIndex:(NSInteger *)index {
    NSMenuItem *mi = [menu insertItemWithTitle:NSLocalizedString(@"Switch Sizes", nil) action:nil keyEquivalent:@"" atIndex:*index];
    if (![self populateOtherSizesMenu:(mi.submenu = [[[NSMenu alloc] initWithTitle:@""] autorelease]) mode:mode])
        [menu removeItem:mi];
    else ++(*index);
//    if ([self insertOtherFamiliesMenu:menu item:item atIndex:*i])
//        ++(*i);
//    if ([self insertOtherBrandsMenu:menu item:item atIndex:*i])
//        ++(*i);
}

- (ArthroplastyTemplate *)itemForViewerContextualMenuMode:(ArthroplastyTemplatingLayerReplacementMode)mode {
    switch (mode) {
        case ArthroplastyTemplatingLayerReplacementModeCup: return _cupTemplate;
        case ArthroplastyTemplatingLayerReplacementModeStem: return _stemTemplate;
        case ArthroplastyTemplatingLayerReplacementModeDistalStem: return _distalStemTemplate;
        default: return nil;
    }
}

- (ROI *)layerForViewerContextualMenuMode:(ArthroplastyTemplatingLayerReplacementMode)mode {
    switch (mode) {
        case ArthroplastyTemplatingLayerReplacementModeCup: return _cupLayer;
        case ArthroplastyTemplatingLayerReplacementModeStem: return _stemLayer;
        case ArthroplastyTemplatingLayerReplacementModeDistalStem: return _distalStemLayer;
        default: return nil;
    }
}

- (ArthroplastyTemplatingLayerReplacementMode)modeForLayer:(ROI *)roi {
    if (roi == _cupLayer) return ArthroplastyTemplatingLayerReplacementModeCup;
    if (roi == _stemLayer) return ArthroplastyTemplatingLayerReplacementModeStem;
    if (roi == _distalStemLayer) return ArthroplastyTemplatingLayerReplacementModeDistalStem;
    return InvalidArthroplastyTemplatingLayerReplacementMode;
}

+ (BOOL)offsetsDefinedForFamily:(ArthroplastyTemplateFamily *)fam {
    NSMutableSet *offsets = [NSMutableSet setWithArray:[fam.templates valueForKeyPath:@"offset"]];
    [offsets removeObject:NSNull.null];
    return (offsets.count != 0);
}

- (BOOL)populateOtherSizesMenu:(NSMenu *)menu mode:(ArthroplastyTemplatingLayerReplacementMode)mode {
    menu.autoenablesItems = NO;
    
    ArthroplastyTemplate *item = [self itemForViewerContextualMenuMode:mode];
    ArthroplastyTemplateFamily *family = [item family];
    
    NSArray<ArthroplastyTemplate *> *templates = family.templates;
    
    NSMutableArray<NSPredicate *> *filters = [NSMutableArray array];
    
    [filters addObject:[NSPredicate predicateWithBlock:^BOOL(ArthroplastyTemplate *t, NSDictionary* bindings) {
        return (t.allowedSides&item.allowedSides) != 0;
    }]];
    
    if ([ArthroplastyTemplatingStepsController offsetsDefinedForFamily:family])
        [filters addObject:[NSPredicate predicateWithFormat:@"offset = %@", item.offset]];
    
//    if (filters.count)
        templates = [templates filteredArrayUsingPredicate:[NSCompoundPredicate andPredicateWithSubpredicates:filters]];
    
    for (ArthroplastyTemplate *t in templates) {
        NSMenuItem *mi = [menu addItemWithTitle:t.size action:@selector(replaceTemplateContextualMenuAction:) keyEquivalent:@""];
        mi.target = self;
        mi.representedObject = @[ @(mode), t ];
        if (t == item) {
            mi.state = NSControlStateValueOn;
            mi.enabled = NO;
        }
    }
    
    return YES;
}

- (ROI *)cupLayer {
    return _cupLayer;
}

- (ROI *)stemLayer {
    return _stemLayer;
}

- (ROI *)distalStemLayer {
    return _distalStemLayer;
}

- (ROI *)femurLayer {
    return _femurLayer;
}

- (void)replaceTemplateContextualMenuAction:(NSMenuItem *)mi {
    ArthroplastyTemplatingLayerReplacementMode mode = [mi.representedObject[0] integerValue];
    ArthroplastyTemplate *t = mi.representedObject[1];
    [self replaceLayer:[self layerForViewerContextualMenuMode:mode] with:t];
}

- (void)removeRoiFromViewer:(ROI *)roi {
	if (!roi) return;
    [[NSNotificationCenter defaultCenter] postNotificationName:OsirixRemoveROINotification object:roi userInfo:nil];
    [_viewerController.roiList[0] removeObject:roi];
}

// landmark OR horizontal axis has changed
- (ROI *)axisChange:(ROI *)axis landmarks:(ROI *)landmark :(ROI *)otherLandmark changed:(BOOL *)changed {
	if (!landmark || landmark.points.count != 1 || !_horizontalAxis) {
		if (axis)
            [self removeRoiFromViewer:axis];
        
		return nil;
	}
	
	BOOL newAxis = !axis;
	if (newAxis) {
		axis = [[[ROI alloc] initWithType:tMesure :[_horizontalAxis pixelSpacingX] :[_horizontalAxis pixelSpacingY] :[_horizontalAxis imageOrigin]] autorelease];
		[axis setDisplayTextualData:NO];
		[axis setThickness:1]; [axis setOpacity:.5];
		[axis setSelectable:NO];
		NSTimeInterval group = [NSDate timeIntervalSinceReferenceDate];
		[landmark setGroupID:group];
		[axis setGroupID:group];
        dispatch_async(dispatch_get_main_queue(), ^{
            [_viewerController.imageView roiSet:axis]; // [*axis setCurView: _viewerController.view]; is not available in horos
            [_viewerController.roiList[_viewerController.imageView.curImage] addObject:axis];
        });
	}
	
	NSPoint horizontalAxisD = [_horizontalAxis.points[0] point] - [_horizontalAxis.points[1] point];
	NSPoint axisPM = [landmark.points[0] point];
	NSPoint axisP0 = axisPM+horizontalAxisD/2;
	NSPoint axisP1 = axisPM-horizontalAxisD/2;
	
	if (otherLandmark) {
		NSPoint otherPM = [otherLandmark.points[0] point];
		axisP1 = NSMakeLine(axisP0, axisP1) * NSMakeLine(otherPM, !NSMakeVector(axisP0, axisP1));
		axisP0 = axisPM;
	}
    
	if (newAxis || (axisP0 != [axis.points[0] point] || axisP1 != [axis.points[1] point])) {
        [axis setPoints:[NSMutableArray arrayWithObjects: [MyPoint point:axisP0], [MyPoint point:axisP1], nil]];
//        [[NSNotificationCenter defaultCenter] postNotificationName:OsirixROIChangeNotification object:axis userInfo:nil];
        
//        [_viewerController bringToFrontROI:landmark]; // TODO: this makes the landmark disappear!
        
        if (changed)
            *changed = YES;
	}
	
	return axis; // returns YES if the axis was changed
}

- (void)updateLegInequality {
    ROI *lm1, *lm2;// = _femurLandmarkOther? ((_femurLandmarkOther==_landmark1)? _landmark2 : _landmark1) : _landmark1, *lm2 = _femurLandmarkOther? _femurLandmarkOther : _landmark2;
    if (_femurLandmarkOther) {
        if (_femurLandmarkOther == _landmark1)
            lm1 = _landmark2;
        else lm1 = _landmark1;
        lm2 = _femurLandmarkOther;
    }
    else {
        lm1 = _landmark1;
        lm2 = _landmark2;
    }
    
    [self updateInequality:@"Original leg inequality" from:lm1 to:lm2 positioning:.5 roi:&_originalLegInequality length:&_originalLegInequalityLength];

    [self updateInequality:@"Leg inequality" from:_femurLandmark to:_femurLandmarkOther positioning:1 roi:&_legInequality length:&_legInequalityLength];
    
//    _landmark1Axis = [self axisChange:_landmark1Axis landmarks:_landmark1:_landmark2 changed:NULL];
//    _landmark2Axis = [self axisChange:_landmark2Axis landmarks:_landmark2:_landmark1 changed:NULL];
    _femurLandmarkAxis = [self axisChange:_femurLandmarkAxis landmarks:_femurLandmark:_femurLandmarkOther changed:NULL];
	
    if (_horizontalAxis && _femurLandmarkOriginal && _femurLandmarkAxis) {
		NSVector horizontalDir = NSMakeVector([_horizontalAxis.points[0] point], [_horizontalAxis.points[1] point]);
		NSLine horizontalAxis = NSMakeLine([_horizontalAxis.points[0] point], horizontalDir);
        NSPoint p1 = horizontalAxis*NSMakeLine(((MyPoint *)_femurLandmarkOriginal.points[0]).point, !horizontalDir), p2 = horizontalAxis*NSMakeLine(((MyPoint *)_femurLandmark.points[0]).point, !horizontalDir);
        
        CGFloat change = [_horizontalAxis Length:p1:p2]; // is an absolute value
        
        // should it be negative?
        BOOL neg = p1.x < p2.x;
        ArthroplastyTemplateSide side = (p1.x > [[_viewerController.imageView curDCM] pwidth]/2)? ArthroplastyTemplateLeftSide : ArthroplastyTemplateRightSide;
        if (side == ArthroplastyTemplateLeftSide)
            neg = !neg;
        
        if (neg)
            change = -change;
        
		_lateralOffsetChange = change;
	}
	
//	NSVector horizontalVector = NSMakeVector([[[_horizontalAxis points] objectAtIndex:0] point], [[[_horizontalAxis points] objectAtIndex:1] point]);
	
//	[_verticalOffsetTextField setStringValue:[NSString stringWithFormat:@"Vertical offset: ", ]];
}

- (void)updateInequality:(NSString *)name from:(ROI *)roiFrom to:(ROI *)roiTo positioning:(CGFloat)positioning roi:(ROI **)axis_ref length:(CGFloat *)value {
//    if (axis == nil)
//        return;
    
//    NSLog(@"updateInequality:%@\n%@\n%@\n%@\n%@", name, roiFrom, roiTo, NSStringFromRect(roiFrom.rect), NSStringFromRect(roiTo.rect));
    
    if (!_horizontalAxis || [[_horizontalAxis points] count] < 2) {
        if (*axis_ref)
            [self removeRoiFromViewer:*axis_ref];
        *axis_ref = nil;
        return;
    }
    
    NSVector horizontalVector = NSMakeVector([_horizontalAxis.points[0] point], [_horizontalAxis.points[1] point]);
    NSLine lineFrom; if (roiFrom) lineFrom = NSMakeLine([roiFrom.points[0] point], horizontalVector);
    NSLine lineTo; if (roiTo) lineTo = NSMakeLine([roiTo.points[0] point], horizontalVector);
    
    if (!roiFrom || !roiTo || NSEqualRects(roiFrom.rect, NSZeroRect) || NSEqualRects(roiTo.rect, NSZeroRect)) {
        if (*axis_ref)
            [self removeRoiFromViewer:*axis_ref];
        *axis_ref = nil;
        return;
    }
    
    ROI *axis = *axis_ref;
    if (!axis) {
        *axis_ref = axis = [[[ROI alloc] initWithType:tMesure :_horizontalAxis.pixelSpacingX :_horizontalAxis.pixelSpacingY :_horizontalAxis.imageOrigin] autorelease];
        [axis setThickness:1]; [axis setOpacity:.5];
        [axis setSelectable:NO];
        axis.name = name;
        
        [HipArthroplastyTemplating onMainThreadPerformOrDispatchSync:^{
            [_viewerController.imageView roiSet:axis]; // [axis setCurView: _viewerController.view]; is not available in horos
            [_viewerController.roiList[_viewerController.imageView.curImage] addObject:axis];
        }];
    }
    
    NSLine inequalityLine = NSMakeLine([roiFrom.points[0] point]*(1.0-positioning)+[roiTo.points[0] point]*positioning, !horizontalVector);
    NSPoint pointFrom = lineFrom*inequalityLine, pointTo = lineTo*inequalityLine;
    
    if (axis.points.count)
        [axis.points removeAllObjects];
    [axis setPoints:[NSMutableArray arrayWithObjects: [MyPoint point:pointFrom], [MyPoint point:pointTo], nil]];
    
    if (value) {
        NSPoint delta = pointTo - pointFrom;
        CGFloat sign = (delta.y < 0)? -1 : 1;
        *value = [axis MesureLength:NULL] * sign * (-1);
    }
    
//    [[NSNotificationCenter defaultCenter] postNotificationName:OsirixROIChangeNotification object:_legInequality userInfo:nil];
}

- (void)observeROIChangedNotification:(NSNotification *)note {
	ROI *roi = note.object;
	if (!roi)
        return;
	
    if (_isMyRoiManupulation) return;
    
	// verify that the ROI is on our viewer
	if (![_viewerController containsROI:roi]) return;
	
	// add to known list
	BOOL wasKnown = [_knownRois containsObject:roi];
	if (!wasKnown) [_knownRois addObject:roi];
	
	// if is _infoBoxRoi then return (we already know about it)
	if (roi == _infoBox) return;	
	
	// step dependant
	if (!wasKnown) {
		if ([_steps currentStep] == _stepCalibration) {
			if (!_magnificationLine && [roi type] == tMesure) {
				_magnificationLine = roi;
				[roi setName:@"Calibration Line"];
			}
        }
		
		if ([_steps currentStep] == _stepAxes)
        {
			if (!_horizontalAxis && [roi type] == tMesure) {
				_horizontalAxis = roi;
				[roi setName:@"Horizontal Axis"];
			} else if (!_femurAxis && [roi type] == tMesure) {
				_femurAxis = roi;
				[roi setName:@"Femur Axis"];
			}
        }
		if ([_steps currentStep] == _stepLandmarks)
        {
			if (!_landmark1 && [roi type] == t2DPoint) {
				_landmark1 = roi;
				[roi setDisplayTextualData:NO];
			} else if (!_landmark2 && [roi type] == t2DPoint) {
				_landmark2 = roi;
				[roi setDisplayTextualData:NO];
			}
        }
        
		if ([_steps currentStep] == _stepCutting)
        {
			if (!_femurRoi && [roi type] == tPencil) {
				_femurRoi = roi;
				[roi setThickness:1]; [roi setOpacity:.5];
				[roi setIsSpline:NO];
				[roi setDisplayTextualData:NO];
			}
        }
		if ([_steps currentStep] == _stepCup || _replacingMode == ArthroplastyTemplatingLayerReplacementModeCup)
        {
			if (!_cupLayer && [roi type] == tLayerROI) {
				_cupLayer = roi;
				_cupTemplate = [[_plugin templatesWindowController] templateAtPath:[roi layerReferenceFilePath]];
			}
        }
        
		if ([_steps currentStep] == _stepStem || (_replacingMode == ArthroplastyTemplatingLayerReplacementModeStem || _replacingMode == ArthroplastyTemplatingLayerReplacementModeDistalStem)) {
            if ([roi type] == tLayerROI) {
                if (!_stemLayer) {
                    _stemLayer = roi;
                    _stemTemplate = [[_plugin templatesWindowController] templateAtPath:[roi layerReferenceFilePath]];
                    NSArray<NSValue *> *points = [_stemTemplate headRotationPointsForProjection:ArthroplastyTemplateAnteriorPosteriorProjection];
                    for (int i = 0; i < 5; ++i) // S = 0 to XXL = 4
                        [[_neckSizePopUpButton itemAtIndex:i] setHidden:NSEqualPoints(points[i].pointValue, NSZeroPoint)];
                    if ([_stemTemplate isProximal] && !_distalStemLayer)
                        [[_plugin templatesWindowController] setFilter:@"Distal Stem"];
                }
                if ([_stemTemplate isProximal] && !_distalStemLayer && [roi type] == tLayerROI) {
                    ArthroplastyTemplate *t = [[_plugin templatesWindowController] templateAtPath:[roi layerReferenceFilePath]];
                    if ([t isDistal]) {
                        _distalStemLayer = roi;
                        _distalStemTemplate = t;
                    }
                }
            }
        }
	}
	
	if (roi == _landmark1 || roi == _landmark2 || roi == _horizontalAxis || roi == _femurLandmark) {
        _landmark1Axis = [self axisChange:_landmark1Axis landmarks:_landmark1:_landmark2 changed:NULL];
        _landmark2Axis = [self axisChange:_landmark2Axis landmarks:_landmark2:_landmark1 changed:NULL];
        _femurLandmarkAxis = [self axisChange:_femurLandmarkAxis landmarks:_femurLandmark:_femurLandmarkOther changed:NULL];
		[self updateLegInequality];
	}

	if (roi == _cupLayer && [_cupLayer.points[0] point] != NSZeroPoint && roi.points.count > 4)
		if (!_cupRotated && _cupLayer.points.count >= 6) {
			_cupRotated = YES;
			if ([_cupLayer pointAtIndex:4].x < [[_viewerController.imageView curDCM] pwidth]/2)
				[_cupLayer rotate:45 :[_cupLayer.points[4] point]];
			else [_cupLayer rotate:-45 :[_cupLayer pointAtIndex:4]];
			[_cupLayer rotate:_horizontalAngle/M_PI*180 :[_cupLayer pointAtIndex:4]];
		}
	
	if (roi == _stemLayer)
		if (!_stemRotated && [[_stemLayer points] count] >= 6) {
			_stemRotated = YES;
			[_stemLayer rotate:(fabs(_femurAngle)-M_PI/2)/M_PI*180 :[_stemLayer.points[4] point]];
		}
    
    if (roi == _stemLayer || roi == _distalStemLayer)
        [self adjustDistalToProximal];
    
    if (!_computeValuesGuard) {
        _computeValuesGuard = YES;
        @try {
            [self computeValues];
        }
        @finally {
            _computeValuesGuard = NO;
        }
    }
}

- (void)observeROIRemovedNotification:(NSNotification *)noti {
	ROI *roi = noti.object;
    
//    NSLog(@"roiremoved %x %@", roi, roi);
	
	[_knownRois removeObject:roi];

    if (roi == _magnificationLine) {
		_magnificationLine = nil;
		[_stepCalibration setDone:NO];
		[_steps setCurrentStep:_stepCalibration];
        NSArray<MyPoint *> *ps = [roi points];
        if (ps.count) {
            BOOL go = YES;
//            MyPoint *p = ps[0];
            for (int i = 1; go && i < ps.count; ++i) {
//                MyPoint *q = [ps objectAtIndex:i];
                if (ps[0].x != ps[i].x || ps[0].y != ps[i].y)
                    go = NO;
            }
            
            if (go) {
                NSThread *thread = [NSThread performBlockInBackground:^{
                    NSThread *thread = [NSThread currentThread];
                    thread.name = NSLocalizedString(@"Calculating object diameter...", nil);
                    thread.status = NSLocalizedString(@"If you didn't click inside a calibration object, you better cancel this calculation.", nil);
                    thread.supportsCancel = YES;
                    
                    NSMutableArray<ArthroplastyTemplatingPoint *> *contour = [NSMutableArray array];
                    if (![ArthroplastyTemplatingGeometry growRegionFromPoint:[ArthroplastyTemplatingPoint pointWith:roundf(ps[0].x):roundf(ps[0].y)] onDCMPix:self.viewerController.pixList[self.viewerController.imageView.curImage] outputPoints:nil outputContour:contour])
                        return;
                    
                    NSArray<ArthroplastyTemplatingPoint *> *ps = [ArthroplastyTemplatingGeometry mostDistantPairOfPointsInArray:contour];
                    
                    if (ps)
                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                            // create the ROI
                            ROI *nroi = [[[ROI alloc] initWithType:tMesure :roi.pixelSpacingX :roi.pixelSpacingY :roi.imageOrigin] autorelease];
                            [nroi addPoint:ps[0].NSPoint];
                            [nroi addPoint:ps[1].NSPoint];
                            [_viewerController.imageView roiSet:nroi]; // [nroi setCurView: _viewerController.view]; is not available in horos
                            [_viewerController.roiList[_viewerController.imageView.curImage] addObject:nroi];
                            [[NSNotificationCenter defaultCenter] postNotificationName:OsirixROIChangeNotification object:nroi userInfo:nil];
                        }];
                }];
                
                NSTimeInterval z = [NSDate timeIntervalSinceReferenceDate];
                while ([NSDate timeIntervalSinceReferenceDate] < z+1) {
                    if ([thread isExecuting])
                        [NSThread sleepForTimeInterval:0.01];
                    else break;
                }
                
                if ([thread isExecuting])
                    [thread startModalForWindow:_viewerController.window];
            }
        }
	}
	
	if (roi == _horizontalAxis) {
		_horizontalAxis = nil;
		[_stepAxes setDone:NO];
		[_steps setCurrentStep:_stepAxes];
		[self updateLegInequality];
	}
	
	if (roi == _femurAxis) {
		_femurAxis = nil;
		[_steps setCurrentStep:_stepAxes];
	}
	
	if (roi == _landmark1) {
		_landmark1 = nil;
        _landmark1Axis = [self axisChange:_landmark1Axis landmarks:_landmark1:_landmark2 changed:NULL]; // removes _landmark1Axis
		if (_landmark2) {
			_landmark1 = _landmark2; _landmark2 = nil;
			_landmark1Axis = _landmark2Axis; _landmark2Axis = nil;
			[_landmark1 setName:@"Landmark 1"];
            BOOL changed = NO;
            _landmark1Axis = [self axisChange:_landmark1Axis landmarks:_landmark1:_landmark2 changed:&changed];
			if (!changed)
				[[NSNotificationCenter defaultCenter] postNotificationName:OsirixROIChangeNotification object:_landmark1 userInfo:nil];
		} else
			[_stepLandmarks setDone:NO];
		[_steps setCurrentStep:_stepLandmarks];
		[self updateLegInequality];
	}
	
	if (roi == _landmark1Axis)
		_landmark1Axis = nil;
	
	if (roi == _landmark2) {
		_landmark2 = nil;
        _landmark1Axis = [self axisChange:_landmark1Axis landmarks:_landmark1:_landmark2 changed:NULL];
        _landmark2Axis = [self axisChange:_landmark2Axis landmarks:_landmark2:_landmark1 changed:NULL];
		[self updateLegInequality];
	}
	
	if (roi == _landmark2Axis)
		_landmark2Axis = nil;

	if (roi == _femurRoi)
		_femurRoi = nil;
	
	if (roi == _femurLayer) {
		_femurLayer = nil; _femurLandmark = nil;
		[self removeRoiFromViewer:_originalFemurOpacityLayer];
		[_stepCutting setDone:NO];
		[_steps setCurrentStep:_stepCutting];
	}
	
	if (roi == _cupLayer) {
		_cupLayer = nil;
		_cupTemplate = nil;
        if (_replacingMode != ArthroplastyTemplatingLayerReplacementModeCup) {
            [_stepCup setDone:NO];
            [_steps setCurrentStep:_stepCup];
        }
        _cupRotated = NO;
	}
	
	if (roi == _stemLayer) {
		_stemLayer = nil;
		_stemTemplate = nil;
        if (_replacingMode != ArthroplastyTemplatingLayerReplacementModeStem) {
            _distalStemLayer = nil;
            _distalStemTemplate = nil;
            [_stepStem setDone:NO];
            [_steps setCurrentStep:_stepStem];
            _stemRotated = NO;
            [_neckSizePopUpButton setEnabled:NO];
        }
	}
        
    if (roi == _distalStemLayer) {
        _distalStemLayer = nil;
        _distalStemTemplate = nil;
        if (_replacingMode != ArthroplastyTemplatingLayerReplacementModeDistalStem) {
            [_stepStem setDone:NO];
            [_steps setCurrentStep:_stepStem];
        }
    }
	
	if (roi == _infoBox)
		_infoBox = nil;
	
	if (roi == _femurLandmark) {
		_femurLandmark = nil;
		[self removeRoiFromViewer:_femurLandmarkAxis];
		[self updateLegInequality];
	}
	
	if (roi == _femurLandmarkAxis)
		_femurLandmarkAxis = nil;
	
	if (roi == _femurLandmarkOther)
		_femurLandmarkOther = nil;
	
	if (roi == _legInequality)
		_legInequality = nil;
	
	if (roi == _originalLegInequality)
		_originalLegInequality = nil;
	
	if (roi == _originalFemurOpacityLayer)
		 _originalFemurOpacityLayer = nil;
		
	if (roi == _femurLandmarkOriginal)
		_femurLandmarkOriginal = nil;
		
	[self advanceAfterInput:nil];
	[self computeValues];
}

#pragma mark General Methods

- (IBAction)resetSBS:(id)sender {
	[self resetSBSUpdatingView:YES];
}

- (void)resetSBSUpdatingView:(BOOL)updateView {
	[self removeRoiFromViewer:_stemLayer];
	[self removeRoiFromViewer:_cupLayer];
	[self removeRoiFromViewer:_femurLayer];
	[self removeRoiFromViewer:_femurRoi];
	[self removeRoiFromViewer:_landmark2];
	[self removeRoiFromViewer:_landmark1];
	[self removeRoiFromViewer:_femurAxis];
	[self removeRoiFromViewer:_horizontalAxis];
	[self removeRoiFromViewer:_magnificationLine];
	[self removeRoiFromViewer:_infoBox];
	[_viewerController roiDeleteAll:self];
	
	if (_planningDate) [_planningDate release]; _planningDate = nil;
	
	if (updateView) {
		[_steps reset:self];
		[_viewerController.imageView display];
	}
}

#pragma mark Templates

- (IBAction)showTemplatesPanel:(id)sender {
	if ([[[_plugin templatesWindowController] window] isVisible]) return;
	[[[_plugin templatesWindowController] window] makeKeyAndOrderFront:sender];
	_userOpenedTemplates = [sender class] == [NSButton class];
}

- (void)hideTemplatesPanel {
	[[[_plugin templatesWindowController] window] orderOut:self];
}

#pragma mark Step by Step

- (void)steps:(N2Steps *)steps willBeginStep:(N2Step *)step {
	if (steps != _steps)
		return; // this should never happen
	
	if ([_steps currentStep] != step)
		[steps setCurrentStep:step];

	BOOL showTemplates = NO, selfKey = NO;
	int tool = tROISelector;

	if (step == _stepCalibration) {
		tool = [_magnificationRadio selectedTag]? tMesure : tROISelector;
		selfKey = YES;
	} else if (step == _stepAxes)
		tool = tMesure;
	else if (step == _stepLandmarks)
		tool = t2DPoint;
	else if (step == _stepCutting) {
		tool = tPencil;
		if (_femurRoi) {
			[_femurRoi setOpacity:1];
			[_femurRoi setSelectable:YES];
			[_femurRoi setROIMode:ROI_selected];
			[[NSNotificationCenter defaultCenter] postNotificationName:OsirixROIChangeNotification object:_femurRoi userInfo:nil];
		}
	} else if (step == _stepCup) {
		showTemplates = [[_plugin templatesWindowController] setFilter:@"Cup | Cage"];
		NSPoint pt = NSZeroPoint;
		for (MyPoint *p in [_femurRoi points])
			pt += [p point];
		pt /= [[_femurRoi points] count];
		[[_plugin templatesWindowController] setSide: (pt.x > [[_viewerController.imageView curDCM] pwidth]/2)? ArthroplastyTemplateLeftSide : ArthroplastyTemplateRightSide ];
	} else if (step == _stepStem) {
		if (_stemLayer)
			[_stemLayer setGroupID:0];
		showTemplates = [[_plugin templatesWindowController] setFilter:@"Stem !Distal"];
		[[_plugin templatesWindowController] setSide: ([_cupLayer pointAtIndex:4].x > [[_viewerController.imageView curDCM] pwidth]/2)? ArthroplastyTemplateLeftSide : ArthroplastyTemplateRightSide ];
	} else if (step == _stepPlacement)
		[self adjustStemToCup];
	else if (step == _stepSave)
		selfKey = YES;
	
    @try {
        if ([_viewerController respondsToSelector:@selector(setToolTag:)])
            [_viewerController setToolTag:(ToolMode)tool];
        else [_viewerController setROIToolTag:(ToolMode)tool];
    } @catch (...) {
        NSLog(@"Warning: HipArthroplastyTemplating toolTag problem...");
    }
    
	if (showTemplates)
		[self showTemplatesPanel:self];
	else if (!_userOpenedTemplates) [self hideTemplatesPanel];
	
	[(N2Panel *)[self window] setCanBecomeKeyWindow:selfKey];
	if (selfKey) {
		if ([[self window] isVisible]) 
			[[self window] makeKeyAndOrderFront:self];
	} // else if (!showTemplates) [[_viewerController window] makeKeyAndOrderFront:self];
}

- (void)steps:(N2Steps *)steps valueChanged:(id)sender {
	// calibration
	if (sender == _magnificationRadio) {
		BOOL calibrate = [_magnificationRadio selectedTag] == 1;
		[_magnificationCustomFactor setEnabled:!calibrate];
		[_magnificationCalibrateLength setEnabled:calibrate];
        if (calibrate)
            [self.window makeFirstResponder:_magnificationCalibrateLength];
        else [self.window makeFirstResponder:_magnificationCustomFactor];
	}
	// placement
	if (sender == _neckSizePopUpButton)
		[self adjustStemToCup:[_neckSizePopUpButton indexOfSelectedItem]];
	
	[self advanceAfterInput:sender];
}

- (void)advanceAfterInput:(id)sender {
	if (sender == _magnificationRadio) {
		BOOL calibrate = [_magnificationRadio selectedTag] == 1;
        
        @try {
            ToolMode tool = (calibrate? tMesure : tROISelector);
            if ([_viewerController respondsToSelector:@selector(setToolTag:)] && ![DCMView isToolforROIs:tool])
                [_viewerController setToolTag:tool];
            else [_viewerController setROIToolTag:tool];
        } @catch (...) {
            NSLog(@"Warning: HipArthroplastyTemplating toolTag problem...");
        }

		[[self window] makeKeyWindow];
		if (calibrate)
			[_magnificationCalibrateLength performClick:self];
		else [_magnificationCustomFactor performClick:self];
	}
	
	[_neckSizePopUpButton setEnabled: _stemLayer != nil];
}

- (BOOL)steps:(N2Steps *)steps shouldValidateStep:(N2Step *)step {
	NSString *errorMessage = nil;
	
	if (step == _stepCalibration) {
		if (![_magnificationRadio selectedTag]) {
			if ([_magnificationCustomFactor floatValue] <= 0)
				errorMessage = @"Please specify a custom magnification factor value.";
		} else
			if (!_magnificationLine)
				errorMessage = @"Please draw a line the size of the calibration object.";
			else if ([_magnificationCalibrateLength floatValue] <= 0)
				errorMessage = @"Please specify the real size of the calibration object.";
	}
	else if (step == _stepAxes) {
		if (!_horizontalAxis)
			errorMessage = @"Please draw a line parallel to the horizontal axis of the pelvis.";
	}
	else if (step == _stepLandmarks) {
		if (!_landmark1)
			errorMessage = @"Please locate one or two landmarks on the proximal femur (e.g. the tips of the greater trochanters).";
	}
	else if (step == _stepCutting) {
		if (!_femurRoi)
			errorMessage = @"Please encircle the proximal femur destined to receive the femoral implant. Femoral head and neck should not be included if you plan to remove them.";
	}
	else if (step == _stepCup) {
		if (!_cupLayer)
			errorMessage = @"Please select an acetabular template, rotate and locate the component into the pelvic bone.";
	}
	else if (step == _stepStem) {
		if (!_stemLayer)
			errorMessage = @"Please select a femoral template, drag it and drop it into the proximal femur, then rotate it.";
        if ([_stemTemplate isProximal] && !_distalStemLayer)
            errorMessage = @"The selected femoral template requires a distal component.";
	}
	else if (step == _stepSave) {
		if ([[_plannersNameTextField stringValue] length] == 0)
			errorMessage = @"The planner's name must be specified.";
	}

	if (errorMessage)
		[[NSAlert alertWithMessageText:[step title] defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"%@", errorMessage] beginSheetModalForWindow:[self window] modalDelegate:nil didEndSelector:nil contextInfo:nil];
	return errorMessage == nil;
}

- (ROI *)closestROIFromSet:(NSSet<ROI *> *)rois toPoints:(NSArray<MyPoint *> *)points {
	NSArray<ROI *> *roisArray = [rois allObjects];
	CGFloat distances[rois.count];
	// fill distances
	for (unsigned i = 0; i < rois.count; ++i) {
		distances[i] = MAXFLOAT;
		if (!roisArray[i]) continue;
		NSPoint roiPoint = [roisArray[i].points[0] point];
		for (unsigned j = 0; j < points.count; ++j)
			distances[i] = std::min(distances[i], NSDistance(roiPoint, points[j].point));
	}
	
	unsigned minIndex = 0;
	for (unsigned i = 1; i < [rois count]; ++i)
		if (distances[i] < distances[minIndex])
			minIndex = i;
	
	return roisArray[minIndex];
}

- (void)steps:(N2Steps *)steps validateStep:(N2Step *)step {
	if (step == _stepCalibration) {
		if ([_magnificationRadio selectedTag]) {
			if (!_magnificationLine || [[_magnificationLine points] count] != 2) return;
//			NSLog(@"_magnificationCalibrateLength %f", [_magnificationCalibrateLength floatValue]);
			[_magnificationCustomFactor setFloatValue:[_magnificationLine MesureLength:NULL]/[_magnificationCalibrateLength floatValue]];
		}
		CGFloat magnificationValue = [_magnificationCustomFactor floatValue];
		[self applyMagnification:magnificationValue];
	}
	else if (step == _stepAxes) {
	}
	else if (step == _stepLandmarks) {
	}
	else if (step == _stepCutting) {
		if (_femurLayer)
			[self removeRoiFromViewer:_femurLayer];
			
		_femurLayer = [_viewerController createLayerROIFromROI:_femurRoi];
		[_femurLayer roiMove:NSMakePoint(-10,10)]; // when the layer is created it is shifted, but we don't want this so we move it back
		[_femurLayer setOpacity:1];
		[_femurLayer setDisplayTextualData:NO];
        
        if (_viewerController.imageView.curDCM.inverseVal && _viewerController.imageView.curDCM.fullwl > 0) {
            NSImage *image = _femurLayer.layerImage; //[[_femurLayer.layerImage copy] autorelease];
            NSBitmapImageRep *rep = (id) image.representations.firstObject;
            if ([rep isKindOfClass:NSBitmapImageRep.class] && rep.bitsPerSample == 8 && rep.samplesPerPixel == 4 && rep.hasAlpha) {
                size_t max = rep.samplesPerPixel * rep.pixelsWide * rep.pixelsHigh;
                unsigned char *data = rep.bitmapData;
                for (size_t i = 0, j = 3; i < max; ++i) {
                    if (i%4 != 3) { // RGBA, only act on RGB
                        if (*(data + j) != 0) // only act if alpha != 0
                            *(data + i) = 255 - *(data + i);
                    }
                    else j = i+4;
                }
            }
            
            //NSBitmapImageRep *inv = [[rep mutableCopy] autorelease];
            
            //_femurLayer.layerImage = [NSImage imageW];
        }
		
		_femurLandmarkOriginal = [self closestROIFromSet:[NSSet setWithObjects:_landmark1, _landmark2, nil] toPoints:[_femurRoi points]];
		_femurLandmark = [[ROI alloc] initWithType:t2DPoint :_femurLandmarkOriginal.pixelSpacingX :_femurLandmarkOriginal.pixelSpacingY :_femurLandmarkOriginal.imageOrigin];
		[_femurLandmark setROIRect:[_femurLandmarkOriginal rect]];
		[_femurLandmark setName:[NSString stringWithFormat:@"%@'",[_femurLandmarkOriginal name]]]; // same name + prime
		[_femurLandmark setDisplayTextualData:NO];
		
		_femurLandmarkOther = _femurLandmarkOriginal == _landmark1? _landmark2 : _landmark1;
        [_viewerController.imageView roiSet:_femurLandmark]; // [_femurLandmark setCurView:_viewerController.view]; is not available in horos
		[_viewerController.roiList[_viewerController.imageView.curImage] addObject:_femurLandmark];
		[[NSNotificationCenter defaultCenter] postNotificationName:OsirixROIChangeNotification object:_femurLandmark userInfo:nil];
		
		// bring the point to front (we don't want it behind the layer)
		[_viewerController bringToFrontROI:_femurLandmark];

		// group the layer and the points
		NSTimeInterval group = [NSDate timeIntervalSinceReferenceDate];
		[_femurLayer setGroupID:group];
		[_femurLandmark setGroupID:group];
		
		// opacity

		NSBitmapImageRep *femur = [NSBitmapImageRep imageRepWithData:[[_femurLayer layerImage] TIFFRepresentation]];
		NSSize size = [[_femurLayer layerImage] size];
		NSBitmapImageRep *bitmap = [[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:size.width pixelsHigh:size.height bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSCalibratedRGBColorSpace bytesPerRow:size.width*4 bitsPerPixel:32] autorelease];
		unsigned char *bitmapData = [bitmap bitmapData];
		NSInteger bytesPerRow = [bitmap bytesPerRow], bitsPerPixel = [bitmap bitsPerPixel];
		for (NSInteger y = 0; y < size.height; ++y)
			for (NSInteger x = 0; x < size.width; ++x) {
				NSInteger base = bytesPerRow*y+bitsPerPixel/8*x;
				bitmapData[base+0] = 0;
				bitmapData[base+1] = 0;
				bitmapData[base+2] = 0;
				bitmapData[base+3] = [[femur colorAtX:x y:y] alphaComponent]>0? 128 : 0;
			}
		
		NSImage *image = [[NSImage alloc] init];
		unsigned kernelSize = 5; 
		NSBitmapImageRep *temp = [bitmap smoothen:kernelSize];
		[image addRepresentation:temp];
		
		_originalFemurOpacityLayer = [_viewerController addLayerRoiToCurrentSliceWithImage:[image autorelease] referenceFilePath:@"none" layerPixelSpacingX:[[_viewerController.imageView curDCM] pixelSpacingX] layerPixelSpacingY:[[_viewerController.imageView curDCM] pixelSpacingY]];
		[_originalFemurOpacityLayer setSelectable:NO];
		[_originalFemurOpacityLayer setDisplayTextualData:NO];
		[_originalFemurOpacityLayer roiMove:[_femurLayer.points[0] point]-[_originalFemurOpacityLayer.points[0] point]-(temp.size-bitmap.size)/2];
		[_originalFemurOpacityLayer setNSColor:[[NSColor redColor] colorWithAlphaComponent:.5]];
        [_viewerController.imageView roiSet:_originalFemurOpacityLayer]; // [_originalFemurOpacityLayer setCurView: _viewerController.imageView]; is not available in horos
		[[NSNotificationCenter defaultCenter] postNotificationName:OsirixROIChangeNotification object:_originalFemurOpacityLayer userInfo:nil];

		[_femurRoi setROIMode:ROI_sleep];
		[_femurRoi setSelectable:NO];
		[_femurRoi setOpacity:0.2];
		[[NSNotificationCenter defaultCenter] postNotificationName:OsirixROIChangeNotification object:_femurRoi userInfo:nil];
		
		[_viewerController selectROI:_femurLayer deselectingOther:YES];
		[_viewerController bringToFrontROI:_femurLayer];
	}
	else if (step == _stepCup) {
	}
	else if (step == _stepStem) {
		[_stemLayer setGroupID:[_femurLayer groupID]];
		[_distalStemLayer setGroupID:[_femurLayer groupID]];
		[_viewerController setMode:ROI_selected toROIGroupWithID:[_femurLayer groupID]];
		[_viewerController bringToFrontROI:_stemLayer];
	}
	else if (step == _stepSave) {
		[[HipArthroplastyTemplating userDefaults] setObject:[_plannersNameTextField stringValue] forKey:PlannersNameUserDefaultKey];
		
		if (_planningDate) [_planningDate release];
		_planningDate = [[NSDate date] retain];
		[self updateInfo];

		DicomStudy *study = [[[_viewerController fileList:0] objectAtIndex:[_viewerController.imageView curImage]] valueForKeyPath:@"series.study"];
		NSArray<DicomSeries *> *seriesArray = [study.series allObjects];

		NSString *namePrefix = @"Planning";

		int n = 1, m;
		for (unsigned i = 0; i < seriesArray.count; i++) {
			NSString *currentSeriesName = seriesArray[i].name;
			if ([currentSeriesName hasPrefix:namePrefix]) {
				m = [[currentSeriesName substringFromIndex:[namePrefix length]+1] intValue];
				if (n <= m) n = m+1;
			}
		}
		
		NSString *name = [NSString stringWithFormat:@"%@ %d", namePrefix, n];
		[_viewerController deselectAllROIs];
		
		NSDictionary *d = [_viewerController exportDICOMFileInt:YES withName:name];
		if (d.count)
            [BrowserController.currentBrowser.database addFilesAtPaths: [NSArray arrayWithObject:[d valueForKey: @"file"]]
                                                                        postNotifications: YES
                                                                                dicomOnly: YES
                                                                      rereadExistingItems: YES
                                                                        generatedByOsiriX: YES];
		else
            [[DicomDatabase activeLocalDatabase] importFilesFromIncomingDir];
		
		// send to PACS
		if ([_sendToPACSButton state]==NSOnState)
			_imageToSendName = [name retain];
		else {
			[_imageToSendName release];
			_imageToSendName = nil;
		}
	}
}

- (CGFloat)estimateRotationOfROI:(ROI *)roi {
    if (roi.points.count > 5)
        return NSAngle(NSMakeVector([roi.points[4] point], [roi.points[5] point]));
    else return NSAngle(NSMakeVector([roi.points[0] point], [roi.points[1] point]));
}

- (void)replaceLayer:(ROI *)roi with:(ArthroplastyTemplate *)t {
    _replacingMode = [self modeForLayer:roi];
    
	NSPoint center = [roi.points[4] point];
	CGFloat angle = [self estimateRotationOfROI:roi];
	NSTimeInterval group = [roi groupID];
	[self removeRoiFromViewer:roi];
	roi = [[_plugin templatesWindowController] createROIFromTemplate:t inViewer:_viewerController centeredAt:center];
	[roi rotate:(angle-[self estimateRotationOfROI:roi])/M_PI*180 :center];
	[roi setGroupID:group];
    
    _replacingMode = InvalidArthroplastyTemplatingLayerReplacementMode;
}

- (void)rotateLayer:(ROI *)roi by:(float)degs {
	NSPoint center = [roi.points[4] point];
	if (roi == _stemLayer && [_stemLayer groupID] == [_femurLayer groupID])
		center = [roi.points[4+_stemNeckSizeIndex] point];
	[roi rotate:degs :center];
}

- (void)rotateLayer:(ROI *)roi byTrackingMouseFrom:(NSPoint)wp1 to:(NSPoint)wp2 {
	wp1 = [_viewerController.imageView ConvertFromNSView2GL:[_viewerController.imageView convertPoint:wp1 fromView:nil]];
	wp2 = [_viewerController.imageView ConvertFromNSView2GL:[_viewerController.imageView convertPoint:wp2 fromView:nil]];
	NSPoint center = [roi.points[4] point];
	if (roi == _stemLayer && [_stemLayer groupID] == [_femurLayer groupID])
		center = [roi.points[4+_stemNeckSizeIndex] point];
	CGFloat angle = NSAngle(center, wp2)-NSAngle(center, wp1);
	[self rotateLayer:roi by:angle/M_PI*180];
}

- (BOOL)handleViewerEvent:(NSEvent *)event {
	if ([event type] == NSKeyDown)
		switch ([event keyCode]) {
			case 76: // enter
			case 36: // return
				[_steps nextStep:_steps.currentStep];
				return YES;
			default:
				unichar uc = [event.charactersIgnoringModifiers characterAtIndex:0];
				BOOL handled = NO;
				switch (uc) {
					case '+':
					case '-':
					case NSUpArrowFunctionKey:
					case NSDownArrowFunctionKey: {
						BOOL next = uc == '+' || uc == NSUpArrowFunctionKey;
						
						if (_cupLayer && [_cupLayer ROImode] == ROI_selected && _cupTemplate) {
                            ArthroplastyTemplate *t = next? [[_cupTemplate family] templateAfter:_cupTemplate] : [[_cupTemplate family] templateBefore:_cupTemplate];
                            if (t) {
                                [self replaceLayer:_cupLayer with:t];
                            }
                            
							handled = YES;
						}
						if (_stemLayer && [_stemLayer ROImode] == ROI_selected && _stemTemplate) {
							ArthroplastyTemplate *t = next? [[_stemTemplate family] templateAfter:_stemTemplate] : [[_stemTemplate family] templateBefore:_stemTemplate];
                            if (t) {
                                id distalLayer = _distalStemLayer, distalTemplate = _distalStemTemplate;
                                [self replaceLayer:_stemLayer with:t];
                                _distalStemLayer = distalLayer; _distalStemTemplate = distalTemplate;
                                [self adjustDistalToProximal];
                            }
							handled = YES;
						}
						if (_distalStemLayer && [_distalStemLayer ROImode] == ROI_selected && _distalStemTemplate) {
							ArthroplastyTemplate *t = next? [[_distalStemTemplate family] templateAfter:_distalStemTemplate] : [[_distalStemTemplate family] templateBefore:_distalStemTemplate];
                            if (t) {
                                [self replaceLayer:_distalStemLayer with:t];
                                [self adjustDistalToProximal];
                            }
                            
							handled = YES;
						}
						
						return handled;
					}
					case '*':
					case '/':
					case NSLeftArrowFunctionKey:
					case NSRightArrowFunctionKey:
						BOOL cw = uc == '*' || uc == NSRightArrowFunctionKey;
						
						if (_cupLayer && [_cupLayer ROImode] == ROI_selected) {
							[self rotateLayer:_cupLayer by:cw? 1 : -1];
							handled = YES;
						}
						if ((_stemLayer && [_stemLayer ROImode] == ROI_selected) || (_distalStemLayer && [_distalStemLayer ROImode] == ROI_selected)) {
							[self rotateLayer:_stemLayer by:cw? 1 : -1];
                            [self adjustDistalToProximal];
							handled = YES;
						}
						
						return handled;
				}
		}
	
	if ([event type] == NSLeftMouseDown || [event type] == NSRightMouseDown || [event type] == NSOtherMouseDown) {
		if ((_cupLayer && [_cupLayer ROImode] == ROI_selected) || (_stemLayer && [_stemLayer ROImode] == ROI_selected)) {
			NSUInteger modifiers = [event modifierFlags]&0xffff0000;
			_isMyMouse = (modifiers == NSCommandKeyMask+NSAlternateKeyMask)? [event retain] : nil;
			return _isMyMouse != nil;
		}
	} else if (_isMyMouse && ([event type] == NSLeftMouseDragged || [event type] == NSRightMouseDragged || [event type] == NSOtherMouseDragged)) {
		if (_cupLayer && [_cupLayer ROImode] == ROI_selected)
			[self rotateLayer:_cupLayer byTrackingMouseFrom:[_isMyMouse locationInWindow] to:[event locationInWindow]];
		if (_stemLayer && [_stemLayer ROImode] == ROI_selected)
			[self rotateLayer:_stemLayer byTrackingMouseFrom:[_isMyMouse locationInWindow] to:[event locationInWindow]];
		[_isMyMouse release];
		_isMyMouse = [event retain];
		return YES;
	} else if ([event type] == NSLeftMouseUp || [event type] == NSRightMouseUp || [event type] == NSOtherMouseUp) {
		if ([_femurLayer groupID] == [_stemLayer groupID])
			[self adjustStemToCup];
		if (_isMyMouse) [_isMyMouse release]; _isMyMouse = nil;
	}
	
	return NO;
}


#pragma mark Steps specific methods

- (void)adjustStemToCup {
	if (!_cupLayer || !_stemLayer)
		return;
    
	NSPoint cupCenter = [_cupLayer.points[4] point];
	
	unsigned magnetsCount = 5;
	NSPoint magnets[magnetsCount];
	CGFloat distances[magnetsCount];
	for (unsigned i = 0; i < magnetsCount; ++i) {
		magnets[i] = [_stemLayer.points[6+i] point];
		distances[i] = NSDistance(cupCenter, magnets[i]);
	}
	
	unsigned indexOfClosestMagnet = 0;
	for (unsigned i = 1; i < magnetsCount; ++i)
		if (distances[i] < distances[indexOfClosestMagnet])
			indexOfClosestMagnet = i;
	
	[self adjustStemToCup:indexOfClosestMagnet];
}

- (void)adjustStemToCup:(NSInteger)index {
	if (!_cupLayer || !_stemLayer)
		return;
	
    ++_isMyRoiManupulation;

	_stemNeckSizeIndex = index;
	
	NSPoint cupCenter = [_cupLayer.points[4] point];
	
	NSUInteger magnetsCount = [[_stemLayer points] count]-6;
	NSPoint magnets[magnetsCount];
	for (unsigned i = 0; i < magnetsCount; ++i)
		magnets[i] = [_stemLayer.points[i+6] point];
	
	for (id loopItem in [[_viewerController roiList:[_viewerController curMovieIndex]] objectAtIndex:[_viewerController.imageView curImage]])
		if ([loopItem groupID] == [_stemLayer groupID])
			[loopItem roiMove:cupCenter-magnets[index]];
	
	[_neckSizePopUpButton setEnabled:YES];
	[_neckSizePopUpButton selectItemAtIndex:index];
    
    --_isMyRoiManupulation;
    
    [self computeValues];
}

- (void)adjustDistalToProximal {
	if (!_stemLayer || !_distalStemLayer || [[_distalStemLayer points] count] < 12 || _stemLayer.points.count < 12)
        return;
    
    // mating is done based on point A (and A2)... The purpose of points B and B2 is unknown (we only were able to check this on Revitan stems)
    
    ++_isMyRoiManupulation;

    CGFloat angle = NSAngle([_stemLayer pointAtIndex:4], [_stemLayer pointAtIndex:5]);

    CGFloat curr = NSAngle([_distalStemLayer pointAtIndex:4], [_distalStemLayer pointAtIndex:5]);
    CGFloat dr = angle-curr;
    if (dr)
        [_distalStemLayer rotate:dr/M_PI*180 :[_distalStemLayer pointAtIndex:4]];
    
    NSPoint dp = [_stemLayer pointAtIndex:11]-[_distalStemLayer pointAtIndex:11]; // 11 is STEM_DISTAL_TO_PROXIMAL_COMP
    if (dp != NSZeroPoint) {
        long m = [_distalStemLayer ROImode];
        [_distalStemLayer setROIMode:ROI_selected];
        [_distalStemLayer roiMove:dp];
        [_distalStemLayer setROIMode:(ROI_mode)m];
    }
    
    --_isMyRoiManupulation;
}

// dicom was added to database, send it to PACS
- (void)observeDatabaseAddNotification:(NSNotification *)note {
	if ([_sendToPACSButton state] && _imageToSendName) {
		[_sendToPACSButton setState:NSOffState];
		
//		NSLog(@"send to PACS");
		DicomStudy *study = _viewerController.imageView.studyObj;
		NSArray<DicomSeries *>	*seriesArray = [study.series allObjects];
//		NSLog(@"[seriesArray count] : %d", [seriesArray count]);
//		NSString *pathOfImageToSend;
		
		DicomImage *imageToSend = nil;
		
		for (unsigned i = 0; i < [seriesArray count]; i++) {
			NSString *currentSeriesName = seriesArray[i].name;
//			NSLog(@"currentSeriesName : %@", currentSeriesName);
			if ([currentSeriesName isEqualToString:_imageToSendName]) {
				NSArray<DicomImage *> *images = seriesArray[i].sortedImages;
//				NSLog(@"[images count] : %d", [images count]);
//				NSLog(@"images : %@", images);
				imageToSend = images.firstObject;
//				pathOfImageToSend = [[images objectAtIndex:0] valueForKey:@"path"];
				//pathOfImageToSend = [images valueForKey:@"path"];
//				NSLog(@"pathOfImageToSend : %@", pathOfImageToSend);
			}
		}
		
//		NSMutableArray *file2Send = [NSMutableArray arrayWithCapacity:1];
		//[file2Send addObject:pathOfImageToSend];
//		[file2Send addObject:imageToSend];
        if (imageToSend)
            [SendController sendFiles:@[ imageToSend ]];
	}
}


#pragma mark Result

- (void)computeValues {
    // horizontal angle
    _horizontalAngle = kInvalidAngle;
    if (_horizontalAxis && [[_horizontalAxis points] count] == 2)
        _horizontalAngle = [_horizontalAxis pointAtIndex:0].x < [_horizontalAxis pointAtIndex:1].x?
            NSAngle([_horizontalAxis pointAtIndex:0], [_horizontalAxis pointAtIndex:1]) :
            NSAngle([_horizontalAxis pointAtIndex:1], [_horizontalAxis pointAtIndex:0]) ;
    
    // femur angle
    _femurAngle = kInvalidAngle;
    if (_femurAxis && [[_femurAxis points] count] == 2)
        _femurAngle = [_femurAxis pointAtIndex:0].y < [_femurAxis pointAtIndex:1].y?
            NSAngle([_femurAxis pointAtIndex:0], [_femurAxis pointAtIndex:1]) :
            NSAngle([_femurAxis pointAtIndex:1], [_femurAxis pointAtIndex:0]) ;
    else if (_horizontalAngle != kInvalidAngle)
        _femurAngle = _horizontalAngle+M_PI/2;
    
    // cup inclination
    if (_cupLayer && [[_cupLayer points] count] >= 6) {
        _cupAngle = -([self estimateRotationOfROI:_cupLayer]-_horizontalAngle)/M_PI*180;
        [_cupAngleTextField setStringValue:[NSString stringWithFormat:@"Rotation angle: %.2f°", _cupAngle]];
    }
    
    // stem inclination
    if (_stemLayer && [[_stemLayer points] count] >= 6) {
        _stemAngle = -([self estimateRotationOfROI:_stemLayer]+M_PI/2-_femurAngle)/M_PI*180;
        [_stemAngleTextField setStringValue:[NSString stringWithFormat:@"Rotation angle: %.2f°", _stemAngle]];
    }
    
    [self updateLegInequality];
    
    [self updateInfo];
}

- (void)createInfoBox {
	if (_femurRoi && [[_femurRoi points] count] > 0 && [_femurRoi pointAtIndex:0] != NSZeroPoint)
		if (_infoBox)
			return;
		else {
			NSPoint pt = NSZeroPoint;
			for (MyPoint *p in [_femurRoi points])
				pt += [p point];
			pt /= [[_femurRoi points] count];
			BOOL left = pt.x < [[_viewerController.imageView curDCM] pwidth]/2;
			_infoBox = [[ROI alloc] initWithType:tText :[_viewerController.imageView pixelSpacingX] :[_viewerController.imageView pixelSpacingY] :[_viewerController.imageView origin]];
			[_infoBox setROIRect:NSMakeRect([[_viewerController.imageView curDCM] pwidth]/4*(left?3:1), [[_viewerController.imageView curDCM] pheight]/3*2, 0, 0)];
            [_viewerController.imageView roiSet:_infoBox]; // [_infoBox setCurView: _viewerController.imageView]; is not available in horos
			[_viewerController.roiList[_viewerController.imageView.curImage] addObject:_infoBox];
			[[NSNotificationCenter defaultCenter] postNotificationName:OsirixROIChangeNotification object:_infoBox userInfo:nil];
			[_infoBox release];
		}
	else
		if (_infoBox)
			[self removeRoiFromViewer:_infoBox];
}

- (void)updateInfo {
	[self createInfoBox];
	if (!_infoBox) return;
	[_infoBox setName:self.info];
}

- (NSString *)info {
    NSMutableString *str = [[[NSMutableString alloc] initWithCapacity:512] autorelease];
    
    [str appendString:@"Hip Arthroplasty Templating"];
    
    if (_originalLegInequality || _legInequality) {
        [str appendFormat:@"\nLeg length discrepancy:\n"];
        if (_originalLegInequality)
            [str appendFormat:@"\tOriginal: %.2f cm\n", _originalLegInequalityLength];
        if (_legInequality)
            [str appendFormat:@"\tFinal: %.2f cm\n", _legInequalityLength];
        if (_originalLegInequality && _legInequality) {
            CGFloat change = fabs(_originalLegInequalityLength - _legInequalityLength);
            [str appendFormat:@"\tVariation: %.2f cm\n", change];
            [_verticalOffsetTextField setStringValue:[NSString stringWithFormat:@"Vertical offset variation: %.2f cm", change]];
        }
        
        if (_horizontalAxis && _femurLandmarkOriginal && _femurLandmarkAxis) {
            [str appendFormat:@"Lateral offset variation: %.2f cm\n", _lateralOffsetChange];
            [_horizontalOffsetTextField setStringValue:[NSString stringWithFormat:@"Lateral offset variation: %.2f cm", _lateralOffsetChange]];
        }
    }
    
    if (_cupLayer) {
        [str appendFormat:@"\nCup: %@\n", [_cupTemplate name]];
        [str appendFormat:@"\tManufacturer: %@\n", [_cupTemplate manufacturer]];
        NSString *dimInfo = nil;
        if (!_cupTemplate.offset)
            dimInfo = [NSString stringWithFormat:@"Size: %@", _cupTemplate.size];
        else dimInfo = [NSString stringWithFormat:@"Offset/Size: %@/%@", _cupTemplate.offset, _cupTemplate.size];
        [str appendFormat:@"\t%@\n", dimInfo];
        [str appendFormat:@"\tRotation: %.2f°\n", _cupAngle];
        [str appendFormat:@"\tReference: %@\n", [_cupTemplate referenceNumber]];
    }
    
    if (_stemTemplate) {
        [str appendFormat:@"\n%@: %@\n", ([_stemTemplate isProximal]? @"Stem Proximal Component" : @"Stem"), [_stemTemplate name]];
        [str appendFormat:@"\tManufacturer: %@\n", [_stemTemplate manufacturer]];
        NSString *dimInfo = nil;
        if (!_stemTemplate.offset)
            dimInfo = [NSString stringWithFormat:@"Size: %@", _stemTemplate.size];
        else dimInfo = [NSString stringWithFormat:@"Offset/Size: %@/%@", _stemTemplate.offset, _stemTemplate.size];
        [str appendFormat:@"\t%@\n", dimInfo];
        [str appendFormat:@"\tReference: %@\n", [_stemTemplate referenceNumber]];
    }
    
    if ([_neckSizePopUpButton isEnabled])
        [str appendFormat:@"\tNeck size: %@\n", [[_neckSizePopUpButton selectedItem] title]];

    if (_distalStemTemplate) {
        [str appendFormat:@"Stem Distal Component: %@\n", [_distalStemTemplate name]];
        [str appendFormat:@"\tManufacturer: %@\n", [_distalStemTemplate manufacturer]];
        [str appendFormat:@"\tSize: %@\n", [_distalStemTemplate size]];
        [str appendFormat:@"\tReference: %@\n", [_distalStemTemplate referenceNumber]];
    }
 
    if ([[_plannersNameTextField stringValue] length])
        [str appendFormat:@"\nPlanned by: %@\n", [_plannersNameTextField stringValue]];
    if (_planningDate)
        [str appendFormat:@"Date: %@\n", _planningDate];

    return str;
}

+ (ArthroplastyTemplatingStepsController *)controllerForROI:(ROI *)roi {
    for (ViewerController *viewer in [ViewerController get2DViewers]) {
        id controller = [[HipArthroplastyTemplating plugin] windowControllerForViewer:viewer];
        if (controller && [viewer containsROI:roi])
            return controller;
    }
    
    return nil;
}

- (ROI *)originalLegInequality {
    return _originalLegInequality;
}

@end

@implementation N2DisclosureBox (ArthroplastyTemplating)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        method_exchangeImplementations(class_getInstanceMethod(N2DisclosureBox.class, @selector(initWithTitle:content:)),
                                       class_getInstanceMethod(N2DisclosureBox.class, @selector(ArthroplastyTemplating_initWithTitle:content:)));
    });
}

/**
 We replace the constructor for this class because in certain conditions (recent macOS APIs) the original NSBox titleCell replacement wouldn't work properly.
 */
- (instancetype)ArthroplastyTemplating_initWithTitle:(NSString *)title content:(NSView *)content {
    if (!(self = [self ArthroplastyTemplating_initWithTitle:title content:content]))
        return nil;
    
    @try {
        id tc = [self valueForKey:@"titleCell"];
        id _tc = [self valueForKey:@"_titleCell"];
        if (tc != _tc) {
            [self setValue:tc forKey:@"_titleCell"];
        }
    }
    @catch (NSException *e) {
        // do nothing
    }
    
    return self;
}

@end
