// swift-tools-version: 5.10
import PackageDescription

/// Nimbus is split into small modules with one-way dependencies:
///
///   WeatherFeature ──▶ WeatherCore ◀── OpenMeteo
///   WidgetFeature  ─┤      ▲    ▲
///         └─▶ DesignSystem ┘    └── LocationKit
///
/// The feature only knows protocols from WeatherCore; the app target plugs in
/// the Open-Meteo client and Core Location.
let package = Package(
    name: "NimbusKit",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "WeatherCore", targets: ["WeatherCore"]),
        .library(name: "OpenMeteo", targets: ["OpenMeteo"]),
        .library(name: "LocationKit", targets: ["LocationKit"]),
        .library(name: "DesignSystem", targets: ["DesignSystem"]),
        .library(name: "WeatherFeature", targets: ["WeatherFeature"]),
        .library(name: "WidgetFeature", targets: ["WidgetFeature"]),
    ],
    targets: [
        // Places, forecasts, conditions and the service contracts. Foundation only.
        .target(name: "WeatherCore"),
        // The Open-Meteo forecast and geocoding APIs (free, no API key).
        .target(name: "OpenMeteo", dependencies: ["WeatherCore"]),
        // "Where am I?" with Core Location, turned into a Place.
        .target(name: "LocationKit", dependencies: ["WeatherCore"]),
        // Colors, formatters and reusable SwiftUI pieces.
        .target(name: "DesignSystem", dependencies: ["WeatherCore"]),
        // Screens and view models.
        .target(name: "WeatherFeature", dependencies: ["WeatherCore", "DesignSystem"]),
        // Home Screen and Lock Screen widgets: entries, the loader and the widget views.
        .target(name: "WidgetFeature", dependencies: ["WeatherCore", "DesignSystem"]),

        .testTarget(name: "WeatherCoreTests", dependencies: ["WeatherCore"]),
        .testTarget(name: "OpenMeteoTests", dependencies: ["OpenMeteo", "WeatherCore"]),
        .testTarget(name: "LocationKitTests", dependencies: ["LocationKit", "WeatherCore"]),
        .testTarget(name: "DesignSystemTests", dependencies: ["DesignSystem", "WeatherCore"]),
        .testTarget(name: "WeatherFeatureTests", dependencies: ["WeatherFeature", "WeatherCore"]),
        .testTarget(name: "WidgetFeatureTests", dependencies: ["WidgetFeature", "WeatherCore"]),
    ]
)
