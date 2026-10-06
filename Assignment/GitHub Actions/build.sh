#!/bin/bash
set -e
echo "================================="
echo "Starting Application Build"
echo "================================="
rm -rf build
mkdir -p build
cp -r app build/
cat > build/build-info.txt <<INFO
Application: Session 16 Calculator API
Build Status: SUCCESS
Commit: ${GITHUB_SHA:-local}
Run: ${GITHUB_RUN_NUMBER:-local}
Build Date: $(date -u)
INFO
echo "Build files:"
ls -la build build/app
echo "Build completed successfully."
