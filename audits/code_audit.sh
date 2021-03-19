#!/bin/bash -e

if [ $# -ne 4 ]; then
    echo "usage: <path/to/repo> <lang> <old commit> <new commit>"
    exit 1
fi

REPO_DIR=$1

SCOPE=$2
OLD=$3
NEW=$4

declare -a KEYWORDS

#KEYWORDS+=('\+\+\+\ ')

initialize_java_symbols() {
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
    KEYWORDS+=(ActivityDelegate)
}

initialize_rust_symbols() {
    KEYWORDS+=("connect\(")
    KEYWORDS+=("recvmsg\(")
    KEYWORDS+=("sendmsg\(")
    KEYWORDS+=("::post\(")
    KEYWORDS+=("::get\(")
}

initialize_cpp_symbols() {
    KEYWORDS+=("PR_GetHostByName")
    KEYWORDS+=("PR_GetIPNodeByName")
    KEYWORDS+=("PR_GetAddrInfoByName")
    KEYWORDS+=("PR_StringToNetAddr")

    KEYWORDS+=("MDNS")
    KEYWORDS+=("mDNS")
    KEYWORDS+=("mdns")

    KEYWORDS+=("TRR")
    KEYWORDS+=("trr")

    KEYWORDS+=("AsyncResolve")
    KEYWORDS+=("asyncResolve")
    KEYWORDS+=("ResolveHost")
    KEYWORDS+=("resolveHost")

    KEYWORDS+=("SOCK_")
    KEYWORDS+=("SOCKET_")
    KEYWORDS+=("_SOCKET")

    KEYWORDS+=("UDPSocket")
    KEYWORDS+=("TCPSocket")

    KEYWORDS+=("PR_Socket")

    KEYWORDS+=("SocketProvider")
    KEYWORDS+=("udp-socket")
    KEYWORDS+=("tcp-socket")
    KEYWORDS+=("tcpsocket")
    KEYWORDS+=("SOCKET")
    KEYWORDS+=("mozilla.org/network")
}

initialize_js_symbols() {
    KEYWORDS+=("AsyncResolve\(")
    KEYWORDS+=("asyncResolve\(")
    KEYWORDS+=("ResolveHost\(")
    KEYWORDS+=("resolveHost\(")

    KEYWORDS+=("udp-socket")
    KEYWORDS+=("udpsocket")
    KEYWORDS+=("tcp-socket")
    KEYWORDS+=("tcpsocket")
    KEYWORDS+=("SOCKET")
    KEYWORDS+=("mozilla.org/network")
}

# Step 1: Initialize scope of audit
EXT=
case "${SCOPE}" in
    "java" | "kt" | "java-kt" )
        EXT="java kt"
        SCOPE="java-kt"
        initialize_java_symbols
        ;;
    "c-cpp" | "c-cxx" | "c" | "cxx" | "cpp" )
        EXT="c cpp h cxx hpp hxx"
        SCOPE="c-cpp"
        initialize_cpp_symbols
        ;;
    "rust" )
        EXT="rs"
        initialize_rust_symbols
        ;;
    "js" )
        EXT="js jsm"
        initialize_js_symbols
        ;;
    * )
        echo "requested language not recognized"
        exit 1
        ;;
esac

cd "$REPO_DIR"

# Step 2: Generate match pattern based on in-scope keywords
function join_by { local d=$1; shift; local f=$1; shift; printf %s "$f" "${@/#/$d}"; }
GREP_LINE="$(join_by \| "${KEYWORDS[@]}")"

# Step 3: Obtain patches for all in-scope files where a keyword is present
declare -a path
for ext in ${EXT}; do
    path+=("*.${ext}")
done
echo "Diffing patches-${OLD}-${NEW}-${SCOPE}.diff from all ${path[*]} files"
# Exclude Deleted and Unmerged files from diff
DIFF_FILTER=ACMRTXB
git diff --color=always --color-moved --diff-filter="${DIFF_FILTER}" -U20 -G"${GREP_LINE}" "$OLD" "$NEW" -- "${path[@]}" > "patches-${OLD}-${NEW}-${SCOPE}.diff"

# Step 4: Highlight the keyword with an annoying, flashing color
export GREP_COLOR="05;37;41"
# Capture the entire file and/or overlap with the previous match, add GREP_COLOR highlighting
grep -A10000 -B10000 --color=always -E "${GREP_LINE}" "patches-${OLD}-${NEW}-${SCOPE}.diff" > "keywords-$OLD-$NEW-$SCOPE.diff"

# Add a 'XXX MATCH XXX' at the end of each matched line, easily searchable.
sed -i 's/\(\x1b\[05;37;41.*\)/\1    XXX MATCH XXX/' "keywords-$OLD-$NEW-$SCOPE.diff"

# Step 5: Review the code changes
echo "Diff generated. View it with:"
echo "  less -R $REPO_DIR/keywords-$OLD-$NEW-$SCOPE.diff"
