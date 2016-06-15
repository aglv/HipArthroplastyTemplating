For *release* builds by Pixmeo, please clone the *pixmeo* branch using the following command:

`git clone --recursive -b distribution git@gitlab.com:volz.io/HipArthroplastyTemplating.git`

Open the HipArthroplastyTemplating Xcode project, and use the *Product > Archive* menu item to build the plugin and generate a ZIP file.

Important: the build process copies the version number from the project's Git environment. 
Building untagged/uncommitted versions of the code will result in an unfriendly version number.
Please do not distribute untagged builds, or builds obtained through the *Build* command.