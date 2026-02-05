#!/bin/bash
if [ ! -d "${SRCROOT}/vendor/whisper.cpp/build-apple/whisper.xcframework" ]; then
  "${SRCROOT}/../scripts/build-whisper-macos-xcframework.sh"
fi
/usr/bin/touch "${SRCROOT}/vendor/whisper.cpp/build-apple/.whisper-xcframework.stamp"

