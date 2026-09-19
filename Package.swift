// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "DueKit",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library( name: "DKSchedule", targets: ["DKSchedule"]),
        .library( name: "DKDueStatus", targets: ["DKDueStatus"]),
        .library( name: "DKReminders", targets: ["DKReminders"]),
        .library( name: "DKStorage", targets: ["DKStorage"]),
        .library( name: "DKUI", targets: ["DKUI"]),
    ],
    targets: [  
        .target(name: "DKSchedule"),
        .target(name: "DKDueStatus"),
        .target(name: "DKReminders", dependencies: ["DKSchedule"]),
        .target(name: "DKStorage"),
        .target(name: "DKUI",
                dependencies: ["DKSchedule", "DKDueStatus"]),
        .testTarget(name: "ScheduleTests",
                    dependencies: ["DKSchedule"]),
        .testTarget(name: "DueStatusTests",
                    dependencies: ["DKDueStatus"]),
        .testTarget(name: "RemindersTests",
                    dependencies: ["DKReminders"])
    ]
)
