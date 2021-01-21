#!/bin/bash -e

if [ $# -ne 3 ]; then
    echo "usage: <path/to/repo> <old commit> <new commit>"
    exit 1
fi

REPO_DIR=$1

OLD=$2
NEW=$3

SCOPE="java" # string: this is the java audit
EXT="java kt"

declare -a KEYWORDS

#KEYWORDS+=('\+\+\+\ ')

# URL access
KEYWORDS+=(URLConnection)
KEYWORDS+=(UrlConnectionDownloader)

# Proxy settings
KEYWORDS+=(ProxySelector)

# Android and java networking and 3rd party libs
KEYWORDS+=("openConnection\(")
KEYWORDS+=("java.net")
KEYWORDS+=("javax.net")
KEYWORDS+=(android.net)
KEYWORDS+=(android.webkit)

# Third Party http libs
KEYWORDS+=(ch.boye.httpclientandroidlib.impl.client)
KEYWORDS+=(okhttp)

# Intents
KEYWORDS+=(IntentHelper)
KEYWORDS+=(openUriExternal)
KEYWORDS+=(getHandlersForMimeType)
KEYWORDS+=(getHandlersForURL)
KEYWORDS+=(getHandlersForIntent)
# KEYOWRDS+=(android.content.Intent) # Common
KEYWORDS+=(startActivity)
KEYWORDS+=(startActivities)
KEYWORDS+=(startBroadcast)
KEYWORDS+=(sendBroadcast)
KEYWORDS+=(sendOrderedBroadcast)
KEYWORDS+=(startService)
KEYWORDS+=(bindService)
KEYWORDS+=(android.app.PendingIntent)
KEYWORDS+=(ActivityHandlerHelper.startIntentAndCatch)
KEYWORDS+=(AppLinksInterceptor)
KEYWORDS+=(AppLinksUseCases)

# Rust symbols
KEYWORDS+=("connect\(")
KEYWORDS+=("recvmsg\(")
KEYWORDS+=("sendmsg\(")
KEYWORDS+=("::post\(")
KEYWORDS+=("::get\(")

cd $REPO_DIR

# Step 1: Generate match pattern based on in-scope keywords
function join_by { local d=$1; shift; local f=$1; shift; printf %s "$f" "${@/#/$d}"; }
GREP_LINE="$(join_by \| ${KEYWORDS[@]})"

# Step 2: Obtain patches for all in-scope files where a keyword is present
echo "Diffing patches-${OLD}-${NEW}-${SCOPE}.diff"
path=
for ext in ${EXT}; do
    path="${path} *.${ext}"
done
# Exclude Deleted and Unmerged files from diff
DIFF_FILTER=ACMRTXB
git diff --color=always --color-moved --diff-filter="${DIFF_FILTER}" -U20 -G"${GREP_LINE}" $OLD $NEW -- ${path} > patches-${OLD}-${NEW}-${SCOPE}.diff

# Step 3: Highlight the keyword with an annoying, flashing color
export GREP_COLOR="05;37;41"
# Capture the entire file and/or overlap with the previous match, add GREP_COLOR highlighting
egrep -A10000 -B10000 --color=always "${GREP_LINE}" patches-${OLD}-${NEW}-${SCOPE}.diff > keywords-$OLD-$NEW-$SCOPE.diff

# Add a 'XXX MATCH XXX' at the end of each matched line, easily searchable.
sed -i 's/\(\x1b\[05;37;41.*\)/\1    XXX MATCH XXX/' keywords-$OLD-$NEW-$SCOPE.diff

# Step 4: Review the code changes
echo "Diff generated. View it with:"
echo "  less -R $REPO_DIR/keywords-$OLD-$NEW-$SCOPE.diff"
