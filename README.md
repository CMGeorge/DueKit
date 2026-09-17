# DueKit

A small Swift package for items that come due on a schedule: next occurrence, overdue / due soon / upcoming, and local reminders.

The library talks about *items*, *due dates*, and *rules*. Your app supplies its own types, screens, and sentences.

## Requirements

- iOS 17+ or macOS 14+
- Swift 6
- Xcode 16+ (Xcode 27 is fine)

## Add the package

In Xcode: **File → Add Package Dependencies…** and use this repository URL. Pin a version tag (for example `1.0.0`), not a branch.

Or in `Package.swift`:

```swift
.package(url: "https://github.com/CMGeorge/DueKit.git", from: "1.0.0")
