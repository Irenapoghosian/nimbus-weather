import WeatherCore
@testable import WidgetFeature
import XCTest

/// Answers with a fixed forecast or a fixed error.
private struct StubForecasts: ForecastService {
    let result: Result<Forecast, WeatherError>

    func forecast(for place: Place) async throws -> Forecast {
        try result.get()
    }
}

final class WidgetFeatureTests: XCTestCase {
    /// 10:15 in Yerevan.
    private let now = Date(timeIntervalSince1970: 1_792_044_900)
    private let yerevan = WidgetDefaults.city

    private func forecast(high: Double = 21, low: Double = 9) -> Forecast {
        let midnight = now.addingTimeInterval(-10 * 3600 - 15 * 60)
        return Forecast(
            place: yerevan,
            timeZone: TimeZone(identifier: "Asia/Yerevan") ?? .gmt,
            current: CurrentConditions(
                time: now, temperature: 18, apparentTemperature: 17, humidity: 50, precipitation: 0,
                windSpeed: 5, windDirection: 90, pressure: 1015, condition: .rain, isDay: true
            ),
            hourly: (0..<48).map { index in
                HourlyForecast(
                    time: midnight.addingTimeInterval(Double(index) * 3600),
                    temperature: Double(index),
                    precipitationChance: nil,
                    condition: .clear,
                    isDay: true
                )
            },
            daily: [DailyForecast(date: midnight, high: high, low: low, precipitationChance: 60, condition: .rain)]
        )
    }

    func testSnapshotTakesNowTodayAndTheNextHours() {
        let snapshot = WeatherEntryLoader.snapshot(from: forecast(), now: now)

        XCTAssertEqual(snapshot.temperature, 18)
        XCTAssertEqual(snapshot.condition, .rain)
        XCTAssertEqual(snapshot.high, 21)
        XCTAssertEqual(snapshot.low, 9)
        XCTAssertEqual(snapshot.hours.count, 6)
        // 10:15 now, so the first slot is the 10:00 hour.
        XCTAssertEqual(snapshot.hours.first?.temperature, 10)
        XCTAssertEqual(snapshot.timeZone.identifier, "Asia/Yerevan")
    }

    func testGaugeAlwaysContainsTheTemperature() {
        let normal = WeatherEntryLoader.snapshot(from: forecast(high: 21, low: 9), now: now)
        XCTAssertEqual(normal.gaugeRange, 9...21)

        // Warmer now than the forecast high: the scale stretches to fit.
        let hotter = WeatherEntryLoader.snapshot(from: forecast(high: 15, low: 9), now: now)
        XCTAssertEqual(hotter.gaugeRange, 9...18)

        // A flat day still gets a usable scale.
        let flat = WeatherEntryLoader.snapshot(from: forecast(high: 18, low: 18), now: now)
        XCTAssertEqual(flat.gaugeRange, 17...19)
    }

    func testLoaderBuildsAnEntryForThePlace() async {
        let loader = WeatherEntryLoader(forecasts: StubForecasts(result: .success(forecast())))
        let entry = await loader.entry(for: yerevan, now: now)

        XCTAssertEqual(entry.place, yerevan)
        XCTAssertEqual(entry.date, now)
        guard case .weather(let snapshot) = entry.content else { return XCTFail("Expected weather") }
        XCTAssertEqual(snapshot.temperature, 18)
        XCTAssertEqual(WeatherEntryLoader.nextRefresh(after: entry), now.addingTimeInterval(30 * 60))
    }

    func testFailuresShowAShortMessageAndRetrySooner() async {
        let offline = await WeatherEntryLoader(forecasts: StubForecasts(result: .failure(.offline))).entry(for: yerevan, now: now)
        let down = await WeatherEntryLoader(forecasts: StubForecasts(result: .failure(.unavailable))).entry(for: yerevan, now: now)

        XCTAssertEqual(offline.content, .unavailable("Offline"))
        XCTAssertEqual(down.content, .unavailable("Unavailable"))
        XCTAssertEqual(WeatherEntryLoader.nextRefresh(after: down), now.addingTimeInterval(10 * 60))
    }

    func testPlaceholderAndSuggestions() {
        let placeholder = WeatherEntry.placeholder(date: now)

        XCTAssertEqual(placeholder.place, WidgetDefaults.city)
        guard case .weather(let snapshot) = placeholder.content else { return XCTFail("Expected weather") }
        XCTAssertEqual(snapshot.hours.count, 6)
        XCTAssertEqual(Set(WidgetDefaults.suggestedCities.map(\.id)).count, WidgetDefaults.suggestedCities.count)
        XCTAssertEqual(WidgetDefaults.suggestedCities.first, WidgetDefaults.city)
    }
}
