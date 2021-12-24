#!/bin/sh -euo pipefail

# Nested frameworks (i.e. having a Frameworks/ folder inside *.app/Frameworks/.framework) is invalid and will make the build be rejected during TestFlight validation.
# This can happen especially due to an Xcode 12.4 UI bug when linking binary frameworks to the project which always embed the binary (and if you try to change to Do Not Embed it also removes it from linked libraries)
# This is a bug in Xcode 12.4 UI that is fixed in Xcode 12.5, so fixing nested frameworks to "Do Not Embed" can be fixed using Xcode 12.5, while still continue using Xcode 12.4 for development after the fix.

# This script is intended to be used as a Build Phase on the main app target, as the very last build phase (and especially after the "Embed Frameworks" phase)

NESTED_FMKS_DIRS=$(find "${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}" -name Frameworks -depth 2) 
if [ -z "$NESTED_FMKS_DIRS" ]; then
    echo "✅ No nested framework found, you're good to go!"
else
    echo "❌ Found nested \`Frameworks\` folder inside frameworks of final bundle."
    for fmk_dir in $NESTED_FMKS_DIRS; do
        # Extract the name of the parent framework containing the nested ones
        parent_fmk=$(basename $(dirname $fmk_dir) .framework)
        # Extract the list of frameworks nested inside that parent framework. In the next command:
        #  * `-depth 1` is to avoid logging cases of "C nested in B itself nested in A" (2+ levels of nesting), since C nested in B will already be logged when looping on fmk_dir=B, so no need to log it during fmk_dir=A too.
        #  * The `sed` command removes the leading `./` in the paths returned by `find`, then quote the results in backticks for nicer formatting in final message.
        #  * The `tr` command joins all the lines (= found frameworks) with a `,`. Note that this will result in an extra comma at the end of the list too, but we'll get rid of that in the final message using ${nested_fmks%,} bash substitution.
        nested_fmks=$(cd "${fmk_dir}" && find . -name '*.framework' -depth 1 | sed "s:^./\(.*\)$:\`\1\`:" | tr '\n' ',')
        echo "error: Found nested frameworks in ${fmk_dir} -- Such a configuration is invalid and will be rejected by TestFlight. Please fix by choosing 'Do Not Embed' for the nested framework(s) ${nested_fmks%,} within the \`${parent_fmk}\` Xcode project which links to them. You might need to use Xcode 12.5 to fix this, due to an Xcode 12.4 bug – see paNNhX-ee-p2"
    done
    exit 1
fi 
