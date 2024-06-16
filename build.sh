#!/bin/bash

set -ex

echo "Build starting..."

# Ensure environment variables are set
if [[ -z "$TYPESENSE_SEARCH_ONLY_API_KEY" || -z "$TYPESENSE_HOST" || -z "$TYPESENSE_PORT" || -z "$TYPESENSE_PROTOCOL" ]]; then
  echo "Environment variables TYPESENSE_SEARCH_ONLY_API_KEY, TYPESENSE_HOST, TYPESENSE_PORT, TYPESENSE_PROTOCOL must be set."
  exit 1
fi

# Install flutter SDK
if cd flutter; then
 git pull && cd .. ;
else git clone https://github.com/flutter/flutter.git;
fi

ls && flutter/bin/flutter doctor && flutter/bin/flutter clean && flutter/bin/flutter config --enable-web

flutter/bin/flutter build web --web-renderer canvaskit --release \
 --dart-define=TYPESENSE_HOST="$TYPESENSE_HOST" --dart-define=TYPESENSE_PORT="$TYPESENSE_PORT" \
 --dart-define=TYPESENSE_PROTOCOL="$TYPESENSE_PROTOCOL" --dart-define=TYPESENSE_SEARCH_ONLY_API_KEY="$TYPESENSE_SEARCH_ONLY_API_KEY"

echo "Build completed."