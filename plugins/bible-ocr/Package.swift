// swift-tools-version: 5.9
// NOTE: the package/product/target name MUST be "BibleOcr" — that is
// fixName("bible-ocr") as computed by the Capacitor CLI, and it is the name
// `npx cap sync ios` writes into ios/App/CapApp-SPM/Package.swift.
// (The Swift class and the JS plugin name stay "BibleOCR".)
import PackageDescription

let package = Package(
    name: "BibleOcr",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "BibleOcr",
            targets: ["BibleOcr"])
    ],
    dependencies: [
        .package(url: "https://github.com/ionic-team/capacitor-swift-pm.git", "6.0.0"..<"10.0.0")
    ],
    targets: [
        .target(
            name: "BibleOcr",
            dependencies: [
                .product(name: "Capacitor", package: "capacitor-swift-pm")
            ],
            path: "ios/Sources/BibleOCR")
    ]
)
