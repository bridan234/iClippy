#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p .build
swiftc -g -o .build/iclippy-regression \
    Sources/Models/ClipboardEntry.swift Sources/Services/AppSettings.swift \
    Sources/Services/StorageManager.swift Sources/Services/ClipboardManager.swift \
    Sources/Services/ImageTextRecognizer.swift Tests/HistoryTests.swift
.build/iclippy-regression
