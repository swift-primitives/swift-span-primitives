// swift-tools-version: 6.3.1

import PackageDescription

let package = Package(
    name: "swift-span-primitives",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .tvOS(.v26),
        .watchOS(.v26),
        .visionOS(.v26),
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
            name: "Span Primitives",
            targets: ["Span Primitives"]
        ),
        .library(
            name: "Span Primitives Test Support",
            targets: ["Span Primitives Test Support"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Span Primitive",
            dependencies: []
        ),
        .target(
            name: "Span Protocol Primitives",
            dependencies: [
                "Span Primitive",
            ]
        ),
        .target(
            name: "Span Primitives",
            dependencies: [
                "Span Primitive",
                "Span Protocol Primitives",
            ]
        ),
        .target(
            name: "Span Primitives Test Support",
            dependencies: [
                "Span Primitives",
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
        .enableExperimentalFeature("LifetimeDependence"),
        .enableExperimentalFeature("SuppressedAssociatedTypes"),
        .enableUpcomingFeature("InferIsolatedConformances"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
