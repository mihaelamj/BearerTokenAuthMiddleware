// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "BearerTokenAuthMiddleware",
    platforms: [
        .macOS(.v13),
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "BearerTokenAuthMiddleware",
            targets: ["BearerTokenAuthMiddleware"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-openapi-runtime", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "BearerTokenAuthMiddleware",
            dependencies: [
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime")
            ]
        )
    ]
)
