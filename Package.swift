// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription


var dependencies: [Package.Dependency] = []
var targets: [Target] = []

#if canImport(OpenCombine)
targets += [
    .target(
       name: "FxSwift",
       dependencies: [
           "OpenCombine",
           .product(name: "OpenCombineFoundation", package: "OpenCombine"),
           .product(name: "OpenCombineDispatch", package: "OpenCombine"),
           .product(name: "OpenCombineShim", package: "OpenCombine"),
       ]
   ),
]
#else
targets += [
    .target(
        name: "FxSwift",
        dependencies: []
    ),
]
#endif

targets += [
    .testTarget(
        name: "FxSwiftTests",
        dependencies: [
            "FxSwift"
        ]
    ),
]


let package = Package(
    name: "FxSwift",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .watchOS(.v6),
        .tvOS(.v13),
    ],
    products: [
        .library(
            name: "FxSwift",
            targets: ["FxSwift"]
        ),
    ],
    dependencies: dependencies,
    targets: targets
)
