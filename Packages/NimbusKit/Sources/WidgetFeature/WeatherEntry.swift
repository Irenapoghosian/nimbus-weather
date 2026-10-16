import Foundation
import WeatherCore
import WidgetKit

/// One hour in the medium widget.
public struct HourSlot: Equatable, Identifiable, Sendable {
    public let time: Date
    public let temperature: Double
    public let condition: WeatherCondition
    public let isDay: Bool

    public var id: Date { time }
}

/// What a widget shows when the forecast loaded.
public struct WeatherSnapshot: Equatable, Sendable {
    public let temperature: Double
    public let condition: WeatherCondition
    public let isDay: Bool
    public let high: Double?
    public let low: Double?
    public let hours: [HourSlot]
    public let timeZone: TimeZone

    /// The Lock Screen gauge's scale: today's low to high, always containing the current
    /// temperature and never zero-width.
    public var gaugeRange: ClosedRange<Double> {
        let bottom = min(low ?? temperature, temperature)
        let top = max(high ?? temperature, temperature)
        return bottom < top ? bottom...top : (bottom - 1)...(top + 1)
    }
}

/// One moment on a widget's timeline.
public struct WeatherEntry: TimelineEntry, Equatable, Sendable {
    public enum Content: Equatable, Sendable {
        case weather(WeatherSnapshot)
        case unavailable(String)
    }

    public let date: Date
    public let place: Place
    public let content: Content

    public init(date: Date, place: Place, content: Content) {
        self.date = date
        self.place = place
        self.content = content
    }

    /// Made-up weather for the widget gallery and while loading.
    public static func placeholder(date: Date = Date()) -> WeatherEntry {
        let hours = (0..<6).map { offset in
            HourSlot(
                time: date.addingTimeInterval(Double(offset) * 3600),
                temperature: 18 + Double(offset % 3),
                condition: offset < 3 ? .partlyCloudy : .clear,
                isDay: true
            )
        }
        let snapshot = WeatherSnapshot(
            temperature: 18,
            condition: .partlyCloudy,
            isDay: true,
            high: 22,
            low: 11,
            hours: hours,
            timeZone: .current
        )
        return WeatherEntry(date: date, place: WidgetDefaults.city, content: .weather(snapshot))
    }
}

/// Cities offered before the user searches, and the one a new widget starts with.
public enum WidgetDefaults {
    public static let city = Place(id: "616052", name: "Yerevan", country: "Armenia", latitude: 40.18, longitude: 44.51)

    public static let suggestedCities = [
        city,
        Place(id: "2643743", name: "London", region: "England", country: "United Kingdom", latitude: 51.51, longitude: -0.13),
        Place(id: "5128581", name: "New York", region: "New York", country: "United States", latitude: 40.71, longitude: -74.01),
        Place(id: "2988507", name: "Paris", region: "Île-de-France", country: "France", latitude: 48.85, longitude: 2.35),
        Place(id: "1850147", name: "Tokyo", country: "Japan", latitude: 35.69, longitude: 139.69),
        Place(id: "2147714", name: "Sydney", region: "New South Wales", country: "Australia", latitude: -33.87, longitude: 151.21),
    ]
}
