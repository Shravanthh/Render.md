// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MarkdownPreview",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-markdown.git", from: "0.3.0")
    ],
    targets: [
        .executableTarget(
            name: "MarkdownPreview",
            dependencies: [.product(name: "Markdown", package: "swift-markdown")],
            path: "MarkdownPreview"
        )
    ]
)
