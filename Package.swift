// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "SwiftBites",
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "3.0.0-rc.2.2.1"),
        .package(url: "https://github.com/vapor/fluent-postgresql.git", from: "1.0.0-rc.2"),
        .package(url: "https://github.com/vapor/auth.git", from: "2.0.0-rc.3"),
	.package(url: "https://github.com/vapor/leaf.git", from: "3.0.0-rc.2.1.2")
    ],
    targets: [
        .target(name: "App", dependencies: ["FluentPostgreSQL", "Vapor", "Authentication", "Leaf"]),
        .target(name: "Run", dependencies: ["App"]),
        .testTarget(name: "AppTests", dependencies: ["App"])
    ]
)

