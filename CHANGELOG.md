## v2.9
- added Medacta MasterLoc (new LAT PLUS and added LAT 13-14), Quadra Short neck (added STD 4-10 and LAT 4-7), Quadra-P STD and LAT, SMS STD and LAT, and X-acta
- added viewer series change guard
- major changes in templates window, most stuff was switched to bindings
- code formatting (pointers)

## v2.8.6
- fixed missing OsiriX 10.0.3 API findSystemFolderOfType:forDomain:

## v2.8.3==
- added Medacta MasterLoc
- fixed double horizontal flip PDF view bug
- fixed ``acceptsFirstMouse:`` problem

## v2.8.2
- added Medacta Versafitcup CC TRIO, updated Versafitcup DM (was VersafitCup System)
- adjusted calibration region growing thresholds
- fixed ROI update notification for calibration

## v2.8.1
- fixing PDF view for Sierra

## v2.8
- macOS 10.12 compatibility

## v2.7.1
- fixed Medacta Mpact & AMIStem H Collared templates
- added Mathys templates
## v2.7 (private release)
- fixed some warnings
- changed threshold calculation for assisted calibration
- fixed wizard release bug

## v2.6
- autorelease some objects instead of releasing them later, cast ROI_mode

## v2.4.5
- Now 100% compatible with new variants of OsiriX: OsiriX-OS, OsiriX MD, ...
- Project now has Development and Release configurations and additional Version and ZIP build phases (please use "Build > Archive" when compiling for the public)

## v2.4.4
- use of M_PI constant instead of pi
- Added Medacta Mpact
- Added Medacta AMIStem H Collared STD
- Added Medacta AMIStem H Collared LAT

## v2.4.3
- is now compatible with Retina macs
- resolved bug with zero original leg inequality

## v2.4.2
- bugfix: if /Library/Application Support/OsiriX doesn't exist then don't try to create it

## v2.4.1
- 1-click calibration also possible with non-thick reference objects thanks to better flood threshold computation

## v2.4
- Added Medacta miniMAX stems
- Added Medacta Amistem size 00
- Added support for proximal/distal stems
- Added manual calibration 1-click auto-detection
- Enhanced DCMView to accept 1st click when unfocused and creating ROIs for this plugin
- Enhanced template centering when dragging from the templates table
- Fixed leg position variation report values

## v2.3.8
- Fixed a double release (free) bug that appears in OsiriX 4.3.0
