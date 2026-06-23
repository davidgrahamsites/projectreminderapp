// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ReminderKit",
    platforms: [
        .iOS(.v17),
        .watchOS(.v10),
        .macOS(.v14)
    ],
    products: [
        .library(name: "ReminderKit", targets: ["ReminderKit"])
    ],
    targets: [
        .target(name: "ReminderKit"),
        .testTarget(name: "ReminderKitTests", dependencies: ["ReminderKit"])
    ]
)
