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
        .package(url: "https://github.com/ordo-one/dollup", from: "1.0.5"),
        .package(url: "https://github.com/rarestype/swift-io", from: "3.1.0"),
        .package(url: "https://github.com/rarestype/ucf", from: "0.3.0"),
        .package(url: "https://github.com/rarestype/u", from: "1.1.0"),
        .package(
            url: "https://github.com/rarestype/swift-github",
            from: "2.1.0",
            traits: [
                .trait(name: "Cryptography"),
            ]
        ),
    ],
    targets: [
        .executableTarget(
            name: "Rarestcheck",
            dependencies: [
                .target(name: "RarestcheckCommands"),

                .product(name: "System_ArgumentParser", package: "swift-io"),
                .product(name: "SystemAsync", package: "swift-io"),
                .product(name: "SystemIO", package: "swift-io"),

                .product(name: "GitHubClient", package: "swift-github"),
                .product(name: "GitHubRSA", package: "swift-github"),
                .product(name: "GitHubAPI", package: "swift-github"),
                .product(name: "UnixCalendar", package: "u"),
                .product(name: "URI", package: "ucf"),
            ]
        ),
        .target(
            name: "RarestcheckCommands",
            dependencies: [
                .product(name: "System_ArgumentParser", package: "swift-io"),
                .product(name: "SystemAsync", package: "swift-io"),
                .product(name: "SystemIO", package: "swift-io"),

                .product(name: "GitHubClient", package: "swift-github"),
                .product(name: "GitHubRSA", package: "swift-github"),
                .product(name: "GitHubAPI", package: "swift-github"),
                .product(name: "UnixCalendar", package: "u"),
                .product(name: "URI", package: "ucf"),
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
