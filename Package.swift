// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription


var dependencies: [Package.Dependency] = []
var targets: [Target] = [
    .executableTarget(
        name: "FxSwift",
        dependencies: []
    ),
    .testTarget(
        name: "FxSwiftTests",
        dependencies: [
            "FxSwift"
        ]
    ),
]

#if !canImport(Combine)
dependencies += [
    .package(url: "https://github.com/OpenCombine/OpenCombine.git", from: "0.13.0")
]

targets = [
    .executableTarget(
        name: "FxSwift",
        dependencies: [
            "OpenCombine",
            .product(name: "OpenCombineFoundation", package: "OpenCombine"),
            .product(name: "OpenCombineDispatch", package: "OpenCombine"),
            .product(name: "OpenCombineShim", package: "OpenCombine"),
        ]
    ),
    .testTarget(
        name: "FxSwiftTests",
        dependencies: [
            "FxSwift"
        ]
    ),
]
#endif


let package = Package(
    name: "FxSwift",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .watchOS(.v6),
        .tvOS(.v13),
    ],
    dependencies: dependencies,
    targets: targets
)
