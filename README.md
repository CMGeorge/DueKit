# DueKit

A small Swift package for items that come due on a schedule: next occurrence, overdue / due soon / upcoming, and local reminders.

The library talks about *items*, *due dates*, and *rules*. Your app supplies its own types, screens, and sentences.

It grew out of a pattern that kept showing up across freelance iOS work: apps for tracking things that recur on a schedule and need a nudge before they're due, whether that's a home-maintenance checklist or a subscription renewal. Those apps need the same handful of hard parts done right — month-end anchoring so a schedule set on the 31st doesn't drift, leap-year handling for Feb 29 items, overdue / due soon / upcoming status compared by calendar day rather than timestamp, and local reminders that reschedule themselves whenever an item changes. Rebuilding and re-testing that logic for every app invites subtle date bugs, so it lives here instead, once, with its own tests, so any app can add its own item type, screens, and wording on top and trust the due-date maths underneath.

## Requirements

- iOS 17+ or macOS 14+
- Swift 6
- Xcode 16+ (Xcode 27 is fine)

## Add the package

In Xcode: **File → Add Package Dependencies…** and use this repository URL. Pin a version tag (for example `1.0.0`), not a branch.

Or in `Package.swift`:

```swift
.package(url: "https://github.com/CMGeorge/DueKit.git", from: "1.0.0")
