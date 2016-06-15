To build the *release* version of the *HipArthroplastyTemplating* plugin for distribution, please *recursively* clone the *distribution* branch of this repository using the following command:

`git clone --recursive -b distribution git@gitlab.com:volz.io/HipArthroplastyTemplating.git`

Change into the *HipArthroplastyTemplating* directory and build (actually *archive*) the project by executing the following commands:

`cd HipArthroplastyTemplating`
`xcodebuild -project HipArthroplastyTemplating.xcodeproj -scheme 'HipArthroplastyTemplating' -configuration Release archive`

The project's build mechanism will open a new *Finder* window, in which you'll will find a ZIP file ready for distribution. Actually, there will be two ZIP files and a dSYM file: make sure not to distribute the wrong file (specifically, don't distribute the *Code* ZIP file).

**Important**: the build process copies the version number from the project's Git environment. 
Building untagged/uncommitted versions of the code will result in an unfriendly version number in the plugin's *Info.plist* file and in ZIP file names.

If you change anything in the project, please specify a new version number by creating a new tag before building, by using the following command:

`git tag `*`v1.2.3.4`*

Please do not distribute untagged builds, or builds obtained through the *build* command: only distribute *archive* builds!

You are free to commit and push the changes you make on the *distribution* branch, and please also share your tags:

`git push; git push --tags`