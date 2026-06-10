#!/bin/bash
flutter build apk --release

# Versiyani pubspec.yaml dan olish
VERSION=$(grep "^version:" pubspec.yaml | sed 's/version: //' | sed 's/+.*//')
BUILD=$(grep "^version:" pubspec.yaml | sed 's/.*+//')

APK_NAME="Gilam-${VERSION}-(${BUILD}).apk"
SRC="build/app/outputs/flutter-apk/app-release.apk"
DEST="build/app/outputs/flutter-apk/${APK_NAME}"

cp "$SRC" "$DEST"
echo ""
echo "✅ APK tayyor: $DEST"
