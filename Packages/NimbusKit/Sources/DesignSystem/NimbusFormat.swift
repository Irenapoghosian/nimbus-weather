import Foundation
import WeatherCore

/// How numbers and times read across the app. Times are shown in the place's time zone.
public enum NimbusFormat {

    /// 18.4 → "18°", -0.3 → "0°" (never "-0°").
    public static func temperature(_ celsius: Double) -> String {
        let rounded = Int(celsius.rounded())
        return "\(rounded == 0 ? 0 : rounded)°"
    }

    /// "15" or "3 PM", following the user's region.
    public static func hour(_ date: Date, in timeZone: TimeZone, locale: Locale = .current) -> String {
        date.formatted(Date.FormatStyle(locale: locale, timeZone: timeZone).hour(.defaultDigits(amPM: .abbreviated)))
    }

    /// "07:12" or "7:12 AM".
    public static func time(_ date: Date, in timeZone: TimeZone, locale: Locale = .current) -> String {
        date.formatted(Date.FormatStyle(date: .omitted, time: .shortened, locale: locale, timeZone: timeZone))
    }

    /// "Today" for the first day, then "Mon", "Tue"…
    public static func weekday(_ date: Date, in timeZone: TimeZone, now: Date = Date(), locale: Locale = .current) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        if calendar.isDate(date, inSameDayAs: now) { return "Today" }
        let style = Date.FormatStyle(locale: locale, timeZone: timeZone).weekday(.abbreviated)
        return date.formatted(style)
    }

    /// "12 km/h NE"
    public static func wind(speed: Double, direction: Int) -> String {
        "\(Int(speed.rounded())) km/h \(ForecastRules.compassDirection(degrees: direction))"
    }

    /// 40 → "40%"
    public static func percent(_ value: Int) -> String {
        "\(value)%"
    }

    /// 1013.2 → "1013 hPa"
    public static func pressure(_ hectopascals: Double) -> String {
        "\(Int(hectopascals.rounded())) hPa"
    }

    /// "H:21° L:9°"
    public static func highLow(high: Double, low: Double) -> String {
        "H:\(temperature(high)) L:\(temperature(low))"
    }
}
