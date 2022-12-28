// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "PMKVObserver",
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "PMKVObserver",
            targets: ["PMKVObserver"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "PMKVObserver",
            dependencies: ["PMKVObserverC"],
            path: "PMKVObserver",
            sources: ["KVObserver.swift"]),
        .target(
            name: "PMKVObserverC",
            dependencies: [],
            path: "PMKVObserver",
            sources: ["KVObserver.m"]),
        .testTarget(
            name: "PMKVObserverTests",
            dependencies: ["PMKVObserver"],
            path: "PMKVObserverTests",
            exclude: ["PMKVObserverTests.m"]),
    ]
)
