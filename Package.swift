// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DayStart",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "DayStart",
            path: "Sources/DayStart"
        )
    ]
)
