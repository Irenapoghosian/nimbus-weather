import DesignSystem
import SwiftUI
import WeatherCore
import WidgetKit

/// Every widget size and Lock Screen style, picked by the family the system asks for.
public struct NimbusWidgetView: View {
    private let entry: WeatherEntry
    @Environment(\.widgetFamily) private var family

    public init(entry: WeatherEntry) {
        self.entry = entry
    }

    public var body: some View {
        content
            .widgetURL(PlaceLink.url(for: entry.place))
            .containerBackground(for: .widget) { background }
    }

    @ViewBuilder
    private var content: some View {
        switch entry.content {
        case .unavailable(let message):
            UnavailableWidgetView(cityName: entry.place.name, message: message, family: family)
        case .weather(let weather):
            switch family {
            case .systemMedium: MediumWeatherView(cityName: entry.place.name, weather: weather)
            case .accessoryCircular: CircularWeatherView(weather: weather)
            case .accessoryRectangular: RectangularWeatherView(cityName: entry.place.name, weather: weather)
            case .accessoryInline: InlineWeatherView(cityName: entry.place.name, weather: weather)
            default: SmallWeatherView(cityName: entry.place.name, weather: weather)
            }
        }
    }

    /// The app's sky behind Home Screen widgets; Lock Screen widgets use the system's own look.
    @ViewBuilder
    private var background: some View {
        switch family {
        case .systemSmall, .systemMedium:
            LinearGradient(colors: SkyPalette.colors(for: sky.condition.sky, isDay: sky.isDay), startPoint: .top, endPoint: .bottom)
        default:
            Color.clear
        }
    }

    private var sky: (condition: WeatherCondition, isDay: Bool) {
        if case .weather(let weather) = entry.content { return (weather.condition, weather.isDay) }
        return (.overcast, true)
    }
}

/// City, big temperature, condition and today's range.
struct SmallWeatherView: View {
    let cityName: String
    let weather: WeatherSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(cityName).font(.headline).lineLimit(1)
            Text(NimbusFormat.temperature(weather.temperature))
                .font(.system(size: 44, weight: .light))
                .minimumScaleFactor(0.7)
            Spacer(minLength: 0)
            ConditionIcon(weather.condition, isDay: weather.isDay).font(.title3)
            Text(weather.condition.title).font(.caption.weight(.semibold)).lineLimit(1)
            HighLowText(weather: weather).font(.caption)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

/// The small widget's header plus the next six hours.
struct MediumWeatherView: View {
    let cityName: String
    let weather: WeatherSnapshot

    var body: some View {
        VStack(spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(cityName).font(.headline).lineLimit(1)
                    Text(NimbusFormat.temperature(weather.temperature)).font(.system(size: 40, weight: .light))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    ConditionIcon(weather.condition, isDay: weather.isDay).font(.title3)
                    Text(weather.condition.title).font(.caption.weight(.semibold))
                    HighLowText(weather: weather).font(.caption)
                }
            }
            HStack(spacing: 0) {
                ForEach(Array(weather.hours.enumerated()), id: \.element.id) { index, hour in
                    VStack(spacing: 4) {
                        Text(index == 0 ? "Now" : NimbusFormat.hour(hour.time, in: weather.timeZone)).font(.caption2.weight(.semibold))
                        ConditionIcon(hour.condition, isDay: hour.isDay).font(.callout)
                        Text(NimbusFormat.temperature(hour.temperature)).font(.caption.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .foregroundStyle(.white)
    }
}

/// Lock Screen circle: a gauge from today's low to high with the temperature in the middle.
struct CircularWeatherView: View {
    let weather: WeatherSnapshot

    var body: some View {
        Gauge(value: weather.temperature, in: weather.gaugeRange) {
            Image(systemName: weather.condition.symbolName(isDay: weather.isDay))
        } currentValueLabel: {
            Text(NimbusFormat.temperature(weather.temperature))
        } minimumValueLabel: {
            Text(NimbusFormat.temperature(weather.gaugeRange.lowerBound))
        } maximumValueLabel: {
            Text(NimbusFormat.temperature(weather.gaugeRange.upperBound))
        }
        .gaugeStyle(.accessoryCircular)
    }
}

/// Lock Screen rectangle: city, temperature, condition and range.
struct RectangularWeatherView: View {
    let cityName: String
    let weather: WeatherSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Label(cityName, systemImage: weather.condition.symbolName(isDay: weather.isDay))
                .font(.headline)
                .widgetAccentable()
            Text("\(NimbusFormat.temperature(weather.temperature)) \(weather.condition.title)")
            HighLowText(weather: weather)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Lock Screen line above the clock: "☁︎ 18° Yerevan".
struct InlineWeatherView: View {
    let cityName: String
    let weather: WeatherSnapshot

    var body: some View {
        Label("\(NimbusFormat.temperature(weather.temperature)) \(cityName)", systemImage: weather.condition.symbolName(isDay: weather.isDay))
    }
}

struct UnavailableWidgetView: View {
    let cityName: String
    let message: String
    let family: WidgetFamily

    var body: some View {
        switch family {
        case .accessoryInline, .accessoryCircular:
            Image(systemName: "exclamationmark.icloud")
        default:
            VStack(alignment: .leading, spacing: 4) {
                Text(cityName).font(.headline)
                Label(message, systemImage: "exclamationmark.icloud").font(.caption)
            }
            .foregroundStyle(family == .accessoryRectangular ? Color.primary : Color.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
}

/// "H:22° L:11°", or nothing when the day's range is unknown.
struct HighLowText: View {
    let weather: WeatherSnapshot

    var body: some View {
        if let high = weather.high, let low = weather.low {
            Text(NimbusFormat.highLow(high: high, low: low))
        }
    }
}
