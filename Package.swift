// swift-tools-version:6.2
import PackageDescription

let package: Package = .init(
    name: "rarestcheck",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(name: "rarestcheck", targets: ["Rarestcheck"]),
    ],
    dependencies: [
        .package(url: "https://github.com/rarestype/swift-io", from: "1.3.1"),
    ],
    targets: [
        .executableTarget(
            name: "Rarestcheck",
            dependencies: [
                .product(name: "System_ArgumentParser", package: "swift-io"),
                .product(name: "SystemAsync", package: "swift-io"),
                .product(name: "SystemIO", package: "swift-io"),
            ]
        ),
    ]
)
for target: Target in package.targets {
    switch target.type {
    case .plugin: continue
    case .binary: continue
    default: break
    }
    {
        $0 = ($0 ?? []) + [
            .enableUpcomingFeature("ExistentialAny")
        ]
    }(&target.swiftSettings)
}
