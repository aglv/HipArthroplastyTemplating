#!/bin/zsh

set -x

path="$TARGET_BUILD_DIR/$UNLOCALIZED_RESOURCES_FOLDER_PATH"

shopt -s nocasematch # ignore case in regex matching

for dir in $path/*/ ; do # all directories
    [[ ! "$dir" =~ templates/$ ]] && continue # skip those that don't end with 'templates' (and separator)
    find "$dir" -type f ! -iname '*.txt' ! -iname '*.pdf' ! -iname '*.plist' -delete
done

exit 0
