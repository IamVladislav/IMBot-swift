// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "IMBot",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "IMBot",
            targets: ["IMBot"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.0.0"),
        .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", from: "5.0.0")
    ],
    targets: [
        .target(
            name: "IMBot",
            dependencies: ["Alamofire", "SwiftyJSON"])
    ]
)
