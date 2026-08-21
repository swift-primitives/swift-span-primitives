// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "swift-span-primitives",
    platforms: [
        .macOS(.v27),
        .iOS(.v27),
        .tvOS(.v27),
        .watchOS(.v27),
        .visionOS(.v27),
    ],
    products: [
        .library(
            name: "Span Primitive",
            targets: ["Span Primitive"]
        ),
        .library(
            name: "Span Protocol Primitives",
            targets: ["Span Protocol Primitives"]
        ),
        .library(
            name: "Span Raw Primitives",
            targets: ["Span Raw Primitives"]
        ),
        .library(
            name: "Span Primitives",
            targets: ["Span Primitives"]
        ),
        .library(
            name: "Span Primitives Test Support",
            targets: ["Span Primitives Test Support"]
        ),
    ],
    dependencies: [

        .package(
            url: "https://github.com/swift-primitives/swift-index-primitives.git",
            branch: "main"
        ),

        .package(
            url: "https://github.com/swift-primitives/swift-byte-primitives.git",
            branch: "main"
        ),

        .package(
            url: "https://github.com/swift-primitives/swift-cardinal-primitives.git",
            branch: "main"
        ),
    ],
    targets: [
        .target(
            name: "Span Primitive",
            dependencies: []
        ),
        .target(
            name: "Span Protocol Primitives",
            dependencies: [
                "Span Primitive",
                .product(name: "Index Primitives", package: "swift-index-primitives"),
            ]
        ),
        .target(
            name: "Span Raw Primitives",
            dependencies: [
                "Span Primitive",
                "Span Protocol Primitives",
                .product(name: "Index Primitives", package: "swift-index-primitives"),
                .product(name: "Byte Primitives", package: "swift-byte-primitives"),
                .product(
                    name: "Cardinal Primitives Standard Library Integration",
                    package: "swift-cardinal-primitives"
                ),
            ]
        ),
        .target(
            name: "Span Primitives",
            dependencies: [
                "Span Primitive",
                "Span Protocol Primitives",
                "Span Raw Primitives",
            ]
        ),
        .target(
            name: "Span Primitives Test Support",
            dependencies: [
                "Span Primitives"
            ],
            path: "Tests/Support"
        ),
        .testTarget(
            name: "Span Primitives Tests",
            dependencies: [
                "Span Primitives",
                "Span Primitives Test Support",
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("Lifetimes"),
        .enableUpcomingFeature("InferIsolatedConformances"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
