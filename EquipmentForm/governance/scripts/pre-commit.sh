#!/usr/bin/env bash
set -euo pipefail
flutter format --set-exit-if-changed .
flutter analyze
flutter test
