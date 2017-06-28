cd "$PROJECT_DIR"

oinfo="$PROJECT_DIR/$INFOPLIST_FILE"
pinfo="$TARGET_BUILD_DIR/$FULL_PRODUCT_NAME/Contents/Info.plist"

plistversion=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$oinfo")
plistsversion=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$oinfo")
if [ -z "$plistversion" ]; then
    echo "warning: CFBundleVersion is not set"
    plistversion="$plistsversion"
fi

version="$plistversion"
tagversion=$(/usr/bin/git describe --tags --dirty)
gitversion=$(/usr/bin/git describe --tags --dirty --always)

if [ -n "$tagversion" ]; then
    if [[ ${tagversion:0:1} == "v" ]]; then
        tagversion=${tagversion:1}
    fi
    version="$tagversion"
else
    echo "warning: no Git tags were found, using version $version from Info.plist"
    version="$version-$gitversion"
fi

if [[ $gitversion == *"dirty"* ]]; then
    date=$(date +%Y%m%d)
    version="$version-$date"
fi

if [ "$DEBUGGING_SYMBOLS" = "YES" ] && [ "$COPY_PHASE_STRIP" != "YES" ]; then
    version="$version-debug"
fi

if [ "$CONFIGURATION" = "Release" ]; then
    if [ "$tagversion" != "$plistversion" ]; then
        echo "warning: Used Info.plist version $plistversion differs from git tag version $tagversion"
    fi
    exit 0
fi

/usr/libexec/PlistBuddy -c "Delete :GitVersion" "$pinfo"
/usr/libexec/PlistBuddy -c "Add :GitVersion string '$gitversion'" "$pinfo"

#/usr/libexec/PlistBuddy -c "Delete :CFBundleShortVersionString" "$pinfo"
#/usr/libexec/PlistBuddy -c "Add :CFBundleShortVersionString string '$version'" "$pinfo"
#
#/usr/libexec/PlistBuddy -c "Delete :CFBundleVersion" "$pinfo"
#/usr/libexec/PlistBuddy -c "Add :CFBundleVersion string '$version'" "$pinfo"

echo "Done"

exit 0
