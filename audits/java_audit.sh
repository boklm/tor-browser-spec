#!/bin/bash -e

if [ $# -ne 3 ]; then
    echo "usage: <path/to/repo> <old commit> <new commit>"
    exit 1
fi

REPO_DIR=$1

OLD=$2
NEW=$3

SCOPE="java" # string: this is the java audit

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

cd $REPO_DIR
#function join_by { local d=$1; shift; local f=$1; shift; printf %s "$f" "${@/#/ $d}"; }
#GREP_LINE="$(join_by \-G ${KEYWORDS[@]})"

#base=`git merge-base ${OLD} ${NEW}`

if [ ! -f "release-${OLD}-${NEW}.diff" ];
#if [ ! -f "release-${base}-${NEW}.diff" ];
then
  echo "Diffing release-${OLD}-${NEW}.diff"
  #echo "Diffing release-${base}-${NEW}.diff"
  git diff --color=always --color-moved $OLD $NEW -U20 > release-${OLD}-${NEW}.diff
  #git diff --color=always --color-moved $base $NEW -U20 > release-${base}-${NEW}.diff
  #git diff --color=always --color-moved -G${GREP_LINE} $OLD $NEW -U20 > release-${OLD}-${NEW}-G.diff
fi

echo "Done with diff"

function join_by { local d=$1; shift; local f=$1; shift; printf %s "$f" "${@/#/$d}"; }

GREP_LINE="$(join_by \| ${KEYWORDS[@]})"
#GREP_LINE="\+\+\+ |$(join_by \| ${KEYWORDS[@]})"

export GREP_COLOR="05;37;41"

# XXX: Arg this sometimes misses file context
#egrep -A40 -B40 --color=always "${GREP_LINE}" release-${base}-${NEW}.diff > keywords-${base}-${NEW}-$SCOPE.diff
egrep -A40 -B40 --color=always "${GREP_LINE}" release-${OLD}-${NEW}.diff > keywords-${OLD}-${NEW}-$SCOPE.diff

echo "Diff generated. View it with:"
#echo "  less -R $REPO_DIR/keywords-$base-$NEW-$SCOPE.diff"
echo "  less -R $REPO_DIR/keywords-$OLD-$NEW-$SCOPE.diff"
