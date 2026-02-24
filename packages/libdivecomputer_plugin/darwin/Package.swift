// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LibDCDarwin",
    platforms: [.iOS(.v14), .macOS(.v11)],
    products: [
        .library(name: "LibDCDarwin", targets: ["LibDCDarwin"]),
    ],
    targets: [
        .target(
            name: "LibDCDarwin",
            path: "Sources/LibDCDarwin"
        ),
    ]
)
