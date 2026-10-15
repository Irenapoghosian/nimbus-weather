import Foundation

/// Pure rules about forecasts, kept out of the views so they are easy to test.
public enum ForecastRules {

    /// The next `count` hours, starting with the hour that contains `now`.
    public static func upcomingHours(_ hourly: [HourlyForecast], from now: Date, count: Int = 24) -> [HourlyForecast] {
        let startOfHour = now.addingTimeInterval(-3600)
        return Array(hourly.filter { $0.time > startOfHour }.prefix(count))
    }

    /// The coldest low and warmest high across the days, for drawing range bars on one scale.
    public static func temperatureSpan(of days: [DailyForecast]) -> ClosedRange<Double>? {
        guard let low = days.map(\.low).min(), let high = days.map(\.high).max(), low <= high else { return nil }
        return low...high
    }

    /// Where a day's range sits on the shared scale, as fractions 0…1 for the bar's start and end.
    public static func barPosition(for day: DailyForecast, in span: ClosedRange<Double>) -> ClosedRange<Double> {
        let width = span.upperBound - span.lowerBound
        guard width > 0 else { return 0...1 }
        let start = (day.low - span.lowerBound) / width
        let end = (day.high - span.lowerBound) / width
        return max(0, start)...min(1, max(start, end))
    }

    /// 0° → "N", 45° → "NE", 200° → "S"…
    public static func compassDirection(degrees: Int) -> String {
        let names = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
        let normalized = ((degrees % 360) + 360) % 360
        let index = Int((Double(normalized) / 45).rounded()) % names.count
        return names[index]
    }

    /// A plain-language UV level, following the WHO scale.
    public static func uvLevel(_ index: Double) -> String {
        switch index {
        case ..<3: "Low"
        case ..<6: "Moderate"
        case ..<8: "High"
        case ..<11: "Very High"
        default: "Extreme"
        }
    }

    /// Rain chances below this are left out of the hourly and daily rows, like Apple Weather.
    public static let notablePrecipitationThreshold = 20

    /// The chance to show under an icon, or `nil` when it isn't worth mentioning.
    public static func notablePrecipitationChance(_ chance: Int?) -> Int? {
        guard let chance, chance >= notablePrecipitationThreshold else { return nil }
        return chance
    }

    /// A short note under "Feels like", comparing it with the measured temperature.
    public static func feelsLikeNote(actual: Double, apparent: Double) -> String {
        let difference = apparent - actual
        if difference <= -2 { return "Feels colder than the actual temperature." }
        if difference >= 2 { return "Feels warmer than the actual temperature." }
        return "Similar to the actual temperature."
    }
}
