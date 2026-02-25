// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Pearl",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "Pearl",
            targets: ["Pearl"]
        ),
    ],
    dependencies: [
        // Anthropic Claude API (future: use official Swift SDK when available)
        // For now, we use URLSession directly — see PearlEngine.swift
    ],
    targets: [
        .target(
            name: "Pearl",
            dependencies: [],
            path: "Pearl"
        ),
    ]
)
