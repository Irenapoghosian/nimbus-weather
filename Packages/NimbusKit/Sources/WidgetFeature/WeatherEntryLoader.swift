import Foundation
import WeatherCore
import WidgetKit

/// Builds widget entries from the same `ForecastService` the app uses.
public struct WeatherEntryLoader: Sendable {
    /// Open-Meteo updates hourly; half an hour keeps widgets fresh without wasting the battery.
    public static let refreshInterval: TimeInterval = 30 * 60
    /// After a failure, try again sooner.
    public static let retryInterval: TimeInterval = 10 * 60

    private let forecasts: ForecastService

    public init(forecasts: ForecastService) {
        self.forecasts = forecasts
    }

    public func entry(for place: Place, now: Date = Date()) async -> WeatherEntry {
        do {
            let forecast = try await forecasts.forecast(for: place)
            return WeatherEntry(date: now, place: place, content: .weather(Self.snapshot(from: forecast, now: now)))
        } catch let error as WeatherError {
            return WeatherEntry(date: now, place: place, content: .unavailable(error == .offline ? "Offline" : "Unavailable"))
        } catch {
            return WeatherEntry(date: now, place: place, content: .unavailable("Unavailable"))
        }
    }

    public func timeline(for place: Place, now: Date = Date()) async -> Timeline<WeatherEntry> {
        let entry = await entry(for: place, now: now)
        return Timeline(entries: [entry], policy: .after(Self.nextRefresh(after: entry)))
    }

    public static func nextRefresh(after entry: WeatherEntry) -> Date {
        switch entry.content {
        case .weather: entry.date.addingTimeInterval(refreshInterval)
        case .unavailable: entry.date.addingTimeInterval(retryInterval)
        }
    }

    public static func snapshot(from forecast: Forecast, now: Date, hourCount: Int = 6) -> WeatherSnapshot {
        let hours = ForecastRules.upcomingHours(forecast.hourly, from: now, count: hourCount).map { hour in
            HourSlot(time: hour.time, temperature: hour.temperature, condition: hour.condition, isDay: hour.isDay)
        }
        return WeatherSnapshot(
            temperature: forecast.current.temperature,
            condition: forecast.current.condition,
            isDay: forecast.current.isDay,
            high: forecast.today?.high,
            low: forecast.today?.low,
            hours: hours,
            timeZone: forecast.timeZone
        )
    }
}
