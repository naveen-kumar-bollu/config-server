#!/bin/sh
set -e

# Decode the base64-encoded keystore to a file if KEYSTORE_BASE64 is set
if [ -n "$KEYSTORE_BASE64" ]; then
    KEYSTORE_TEMP_PATH="${KEYSTORE_TEMP_PATH:-/tmp/server.jks}"
    echo "$KEYSTORE_BASE64" | base64 -d > "$KEYSTORE_TEMP_PATH"
    export KEYSTORE_LOCATION="file:$KEYSTORE_TEMP_PATH"
    echo "Keystore decoded to $KEYSTORE_TEMP_PATH"
else
    echo "KEYSTORE_BASE64 not set; skipping keystore setup (encryption disabled)"
fi

exec java \
    -XX:+UseContainerSupport \
    -XX:MaxRAMPercentage=75.0 \
    -XX:+UseG1GC \
    -Djava.security.egd=file:/dev/./urandom \
    -jar /app/app.jar "$@"
