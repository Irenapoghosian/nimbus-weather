import DesignSystem
import Foundation
import WeatherCore

/// One tile in the details grid: "Humidity · 64%".
public struct DetailItem: Identifiable, Equatable, Sendable {
    public let title: String
    public let systemImage: String
    public let value: String
    public let footnote: String?

    public var id: String { title }
}

/// What the details grid shows for a forecast, decided outside the view so it can be tested.
public enum ForecastDetails {
    public static func items(for forecast: Forecast, locale: Locale = .current) -> [DetailItem] {
        let current = forecast.current
        var items = [
            DetailItem(
                title: "Feels like",
                systemImage: "thermometer.medium",
                value: NimbusFormat.temperature(current.apparentTemperature),
                footnote: ForecastRules.feelsLikeNote(actual: current.temperature, apparent: current.apparentTemperature)
            ),
            DetailItem(title: "Humidity", systemImage: "humidity", value: NimbusFormat.percent(current.humidity), footnote: nil),
            DetailItem(
                title: "Wind",
                systemImage: "wind",
                value: NimbusFormat.wind(speed: current.windSpeed, direction: current.windDirection),
                footnote: nil
            ),
            DetailItem(title: "Pressure", systemImage: "gauge.medium", value: NimbusFormat.pressure(current.pressure), footnote: nil),
        ]
        if let uvIndex = forecast.today?.uvIndexMax {
            items.append(DetailItem(
                title: "UV index",
                systemImage: "sun.max",
                value: String(Int(uvIndex.rounded())),
                footnote: ForecastRules.uvLevel(uvIndex)
            ))
        }
        if let sunrise = forecast.today?.sunrise, let sunset = forecast.today?.sunset {
            items.append(DetailItem(
                title: "Sunrise",
                systemImage: "sunrise.fill",
                value: NimbusFormat.time(sunrise, in: forecast.timeZone, locale: locale),
                footnote: "Sunset: \(NimbusFormat.time(sunset, in: forecast.timeZone, locale: locale))"
            ))
        }
        return items
    }
}
