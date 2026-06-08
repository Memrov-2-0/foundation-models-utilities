// swift-tools-version: 6.2
import PackageDescription

let package = Package(
  name: "foundation-models-utilities",
  platforms: [
    .macOS("27.0"),
    .iOS("27.0"),
    .visionOS("27.0"),
    .watchOS("27.0")
  ],
  products: [
    .library(
      name: "FoundationModelsUtilities",
      targets: ["FoundationModelsUtilities"]
    )
  ],
  targets: [
    .target(
      name: "FoundationModelsUtilities",
      dependencies: [],
      swiftSettings: [
        .enableExperimentalFeature("InternalImportsByDefault"),
        .enableExperimentalFeature("NonisolatedNonsendingByDefault"),
        .enableUpcomingFeature("MemberImportVisibility")
      ]
    ),
    .testTarget(
      name: "FoundationModelsUtilitiesTests",
      dependencies: [
        "FoundationModelsUtilities",
      ],
      swiftSettings: [
        .enableExperimentalFeature("InternalImportsByDefault"),
        .enableExperimentalFeature("NonisolatedNonsendingByDefault"),
        .enableUpcomingFeature("MemberImportVisibility")
      ]
    ),
  ],
  swiftLanguageModes: [.v6]
)
