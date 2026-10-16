import OpenMeteo
import SwiftUI
import WeatherCore
import WidgetFeature
import WidgetKit

@main
struct NimbusWidgetBundle: WidgetBundle {
    var body: some Widget {
        WeatherWidget()
    }
}

/// The extension's composition root, like `AppContainer` in the app: the same Open-Meteo client,
/// the same rules, no copy of the networking code.
enum WidgetDependencies {
    static let openMeteo = OpenMeteoClient()
    static let loader = WeatherEntryLoader(forecasts: openMeteo)
}

struct WeatherWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "WeatherWidget", intent: SelectCityIntent.self, provider: WeatherProvider()) { entry in
            NimbusWidgetView(entry: entry)
        }
        .configurationDisplayName("Weather")
        .description("The weather in a city you choose. Tap to open it in Nimbus.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

struct WeatherProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> WeatherEntry {
        .placeholder()
    }

    func snapshot(for configuration: SelectCityIntent, in context: Context) async -> WeatherEntry {
        if context.isPreview { return .placeholder() }
        return await WidgetDependencies.loader.entry(for: configuration.place)
    }

    func timeline(for configuration: SelectCityIntent, in context: Context) async -> Timeline<WeatherEntry> {
        await WidgetDependencies.loader.timeline(for: configuration.place)
    }
}

#Preview("Small", as: .systemSmall) {
    WeatherWidget()
} timeline: {
    WeatherEntry.placeholder()
}

#Preview("Medium", as: .systemMedium) {
    WeatherWidget()
} timeline: {
    WeatherEntry.placeholder()
}

#Preview("Lock Screen", as: .accessoryRectangular) {
    WeatherWidget()
} timeline: {
    WeatherEntry.placeholder()
}
