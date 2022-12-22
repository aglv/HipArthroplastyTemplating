//
//  ArthroplastyTemplatingStepsController.h
//  HipArthroplastyTemplating
//  Created by Joris Heuberger on 04/04/07.
//  Copyright 2007-2016 OsiriX Team
//  Copyright 2017 volz.io
//

#import <Cocoa/Cocoa.h>

@class N2Step, N2Steps, N2StepsView, ROI, ArthroplastyTemplate, ViewerController;
@class HipArthroplastyTemplating;

@interface ArthroplastyTemplatingStepsController : NSWindowController {
	HipArthroplastyTemplating *_plugin;
	ViewerController *_viewerController;
	
	IBOutlet N2Steps *_steps;
	IBOutlet N2StepsView *_stepsView;
    
    N2Step *_stepCalibration;
    N2Step *_stepAxes;
    N2Step *_stepLandmarks;
    N2Step *_stepCutting;
    N2Step *_stepCup;
    N2Step *_stepStem;
    N2Step *_stepPlacement;
    N2Step *_stepSave;
    
    IBOutlet NSView *_viewCalibration;
    IBOutlet NSView *_viewAxes;
    IBOutlet NSView *_viewLandmarks;
    IBOutlet NSView *_viewCutting;
    IBOutlet NSView *_viewCup;
    IBOutlet NSView *_viewStem;
    IBOutlet NSView *_viewPlacement;
    IBOutlet NSView *_viewSave;
    
    IBOutlet NSButton *doneCalibration;
    IBOutlet NSButton *doneAxes;
    IBOutlet NSButton *doneLandmarks;
    IBOutlet NSButton *doneCutting;
    IBOutlet NSButton *doneCup;
    IBOutlet NSButton *doneStem;
    IBOutlet NSButton *donePlacement;
    IBOutlet NSButton *doneSave;
	
	NSMutableSet *_knownRois;
    ROI *_magnificationLine;
    ROI *_horizontalAxis;
    ROI *_femurAxis;
    ROI *_landmark1;
    ROI *_landmark2;
    ROI *_femurRoi;
	ROI *_landmark1Axis;
    ROI *_landmark2Axis;
    ROI *_legInequality;
    ROI *_originalLegInequality;
    ROI *_originalFemurOpacityLayer;
    ROI *_femurLayer;
    ROI *_cupLayer;
    ROI *_stemLayer;
    ROI *_distalStemLayer;
    ROI *_infoBox;
	ROI *_femurLandmark;
    ROI *_femurLandmarkAxis;
    ROI *_femurLandmarkOther;
    ROI *_femurLandmarkOriginal;
	
    CGFloat _legInequalityLength;
    CGFloat _originalLegInequalityLength;
    CGFloat _lateralOffsetChange;
	
	// calibration
	IBOutlet NSMatrix *_magnificationRadio;
	IBOutlet NSTextField *_magnificationCustomFactor;
    IBOutlet NSTextField *_magnificationCalibrateLength;
	CGFloat _appliedMagnification;
	// axes
	float _horizontalAngle, _femurAngle;
	// cup
	IBOutlet NSTextField *_cupAngleTextField;
	float _cupAngle;
	BOOL _cupRotated;
	ArthroplastyTemplate *_cupTemplate;
	// stem
	IBOutlet NSTextField *_stemAngleTextField;
	float _stemAngle;
	BOOL _stemRotated;
	ArthroplastyTemplate *_stemTemplate;
    // distal stem
	ArthroplastyTemplate *_distalStemTemplate;
	// placement
	IBOutlet NSPopUpButton *_neckSizePopUpButton;
	IBOutlet NSTextField *_verticalOffsetTextField;
	IBOutlet NSTextField *_horizontalOffsetTextField;
	NSUInteger _stemNeckSizeIndex;

	IBOutlet NSTextField *_plannersNameTextField;
	
	NSPoint _planningOffset;
	NSDate *_planningDate;
	BOOL _userOpenedTemplates;
	
	IBOutlet NSButton *_sendToPACSButton;
	NSString *_imageToSendName;
	NSEvent *_isMyMouse;
    NSInteger _isMyRoiManupulation;
    
    BOOL _computeValuesGuard;
}

@property(readonly) ViewerController *viewerController;
//@property(readonly) CGFloat magnification;

- (id)initWithPlugin:(HipArthroplastyTemplating *)plugin viewerController:(ViewerController *)viewerController;

- (void)populateViewerContextualMenu:(NSMenu *)menu forROI:(ROI *)roi;

- (ROI *)cupLayer;
- (ROI *)stemLayer;
- (ROI *)distalStemLayer;
- (ROI *)femurLayer;

#pragma mark Templates

- (IBAction)showTemplatesPanel:(id)sender;
- (void)hideTemplatesPanel;

#pragma mark General Methods

- (IBAction)resetSBS:(id)sender;
- (void)resetSBSUpdatingView:(BOOL)updateView;

#pragma mark StepByStep Delegate Methods

- (void)steps:(N2Steps *)steps willBeginStep:(N2Step *)step;
- (void)advanceAfterInput:(id)change;
- (void)steps:(N2Steps *)steps valueChanged:(id)sender;
- (BOOL)steps:(N2Steps *)steps shouldValidateStep:(N2Step *)step;
- (void)steps:(N2Steps *)steps validateStep:(N2Step *)step;
- (BOOL)handleViewerEvent:(NSEvent *)event;

#pragma mark Steps specific Methods

- (void)adjustStemToCup;

#pragma mark Result

- (void)computeValues;
- (void)updateInfo;

- (NSString *)info;

@end
