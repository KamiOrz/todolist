// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TodoList",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "TodoList", targets: ["TodoList"])],
    targets: [
        .target(name: "TodoCore"),
        .executableTarget(name: "TodoList", dependencies: ["TodoCore"]),
        .testTarget(name: "TodoCoreTests", dependencies: ["TodoCore"])
    ]
)
