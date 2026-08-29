// swift-tools-version:6.2
import PackageDescription

let package: Package = .init(
    name: "SampleProject",
    platforms: [.macOS(.v15)],
    dependencies: [
        .package(url: "https://github.com/ordo-one/lexic", from: "1.8.0"),
    ],
    targets: [
        .executableTarget(
            name: "Sample",
            dependencies: [
                .product(name: "Bijection", package: "lexic"),
                .product(name: "Assert", package: "lexic"),
            ]
        ),
    ]
)
