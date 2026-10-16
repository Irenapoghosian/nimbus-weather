import DesignSystem
import Foundation
import WeatherCore

/// What the hourly chart plots.
public enum ChartMetric: String, CaseIterable, Identifiable, Sendable {
    case temperature
    case precipitation

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .temperature: "Temperature"
        case .precipitation: "Rain"
        }
    }
}

/// One hour on the chart.
public struct ChartPoint: Identifiable, Equatable, Sendable {
    public let time: Date
    public let temperature: Double
    /// 0…100; an hour without an estimate counts as 0.
    public let precipitationChance: Double

    public var id: Date { time }

    public func value(for metric: ChartMetric) -> Double {
        switch metric {
        case .temperature: temperature
        case .precipitation: precipitationChance
        }
    }
}

/// The chart's data, scale and labels, kept out of the view so they can be tested.
public enum HourlyChartData {
    public static func points(from hours: [HourlyForecast]) -> [ChartPoint] {
        hours.map { hour in
            ChartPoint(time: hour.time, temperature: hour.temperature, precipitationChance: Double(hour.precipitationChance ?? 0))
        }
    }

    /// The y-axis range: whole degrees with room above and below the curve, at least 6° tall so a flat
    /// day doesn't look dramatic; always 0–100% for rain.
    public static func domain(for metric: ChartMetric, points: [ChartPoint]) -> ClosedRange<Double> {
        switch metric {
        case .precipitation:
            return 0...100
        case .temperature:
            guard let low = points.map(\.temperature).min(), let high = points.map(\.temperature).max() else { return 0...10 }
            let padding = max(2, (6 - (high - low)) / 2)
            return (low - padding).rounded(.down)...(high + padding).rounded(.up)
        }
    }

    /// The hour closest to where the finger is.
    public static func nearest(to date: Date?, in points: [ChartPoint]) -> ChartPoint? {
        guard let date else { return nil }
        return points.min { abs($0.time.timeIntervalSince(date)) < abs($1.time.timeIntervalSince(date)) }
    }

    /// The hours that get a label on the x-axis: 00, 06, 12 and 18 in the city's own time zone.
    /// (Swift Charts' own date labels follow the phone's time zone, so Los Angeles would show Yerevan's hours.)
    public static func axisDates(for points: [ChartPoint], in timeZone: TimeZone, every step: Int = 6) -> [Date] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return points.map(\.time).filter { calendar.component(.hour, from: $0) % step == 0 }
    }

    /// "18°" or "40%".
    public static func label(_ value: Double, metric: ChartMetric) -> String {
        switch metric {
        case .temperature: NimbusFormat.temperature(value)
        case .precipitation: NimbusFormat.percent(Int(value.rounded()))
        }
    }
}
