#!/usr/bin/env bash
# Builds the LedGix Rent site for Firebase Hosting (public dir: build/hosting).
#
#   /                 landing page            (landing/)
#   /privacy/         privacy policy          (landing/privacy/)
#   /app/             Flutter web app         (flutter build web --base-href /app/)
#   /hub-callback     LedGix ID return URL    (firebase.json rewrites it to /app/index.html)
#
# Usage: tool/build_web.sh              Firebase build (needs lib/firebase_options.dart)
#        USE_FIREBASE=false tool/build_web.sh   demo build
# WEB_VAPID_KEY is read from the environment, or from secrets/secrets.txt if present.
set -euo pipefail
cd "$(dirname "$0")/.."

# secrets/ lives in the main checkout; worktrees find it through git's common dir.
secrets_file=secrets/secrets.txt
if [[ ! -f "$secrets_file" ]]; then
  secrets_file="$(dirname "$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null || echo .)")/secrets/secrets.txt"
fi
if [[ -z "${WEB_VAPID_KEY:-}" && -f "$secrets_file" ]]; then
  WEB_VAPID_KEY="$(grep -oE 'public key\) : [A-Za-z0-9_-]+' "$secrets_file" | awk '{print $NF}' || true)"
fi

defines=(--dart-define=USE_FIREBASE="${USE_FIREBASE:-true}")
if [[ -n "${WEB_VAPID_KEY:-}" ]]; then defines+=(--dart-define=WEB_VAPID_KEY="$WEB_VAPID_KEY"); fi

flutter build web --release --base-href /app/ "${defines[@]}"

rm -rf build/hosting
mkdir -p build/hosting
cp -R landing/. build/hosting/
cp -R build/web build/hosting/app
# Firebase Cloud Messaging registers its service worker from the site root.
if [[ -f build/web/firebase-messaging-sw.js ]]; then
  cp build/web/firebase-messaging-sw.js build/hosting/firebase-messaging-sw.js
fi

echo "Built build/hosting: landing at /, app at /app/"
