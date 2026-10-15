import WeatherCore
import XCTest

final class ForecastRulesTests: XCTestCase {
    private let start = Date(timeIntervalSince1970: 1_792_040_400)

    private func hours(_ count: Int) -> [HourlyForecast] {
        (0..<count).map { index in
            HourlyForecast(
                time: start.addingTimeInterval(Double(index) * 3600),
                temperature: Double(index),
                precipitationChance: nil,
                condition: .clear,
                isDay: true
            )
        }
    }

    private func day(low: Double, high: Double) -> DailyForecast {
        DailyForecast(date: start, high: high, low: low, precipitationChance: nil, condition: .clear)
    }

    func testUpcomingHoursStartWithTheCurrentHour() {
        let now = start.addingTimeInterval(2 * 3600 + 15 * 60)   // 15 minutes into the third hour
        let upcoming = ForecastRules.upcomingHours(hours(48), from: now)

        XCTAssertEqual(upcoming.count, 24)
        XCTAssertEqual(upcoming.first?.temperature, 2)
    }

    func testUpcomingHoursNearTheEndOfTheForecastAreShorter() {
        let now = start.addingTimeInterval(45 * 3600)
        XCTAssertEqual(ForecastRules.upcomingHours(hours(48), from: now, count: 24).count, 3)
    }

    func testTemperatureSpanCoversTheWholeWeek() {
        let span = ForecastRules.temperatureSpan(of: [day(low: 4, high: 12), day(low: -2, high: 9), day(low: 6, high: 18)])
        XCTAssertEqual(span, -2...18)
        XCTAssertNil(ForecastRules.temperatureSpan(of: []))
    }

    func testBarPositionIsAFractionOfTheSpan() {
        XCTAssertEqual(ForecastRules.barPosition(for: day(low: 5, high: 15), in: 0...20), 0.25...0.75)
        XCTAssertEqual(ForecastRules.barPosition(for: day(low: 0, high: 20), in: 0...20), 0...1)
    }

    func testBarPositionStaysInsideTheBar() {
        XCTAssertEqual(ForecastRules.barPosition(for: day(low: -5, high: 30), in: 0...20), 0...1)
        XCTAssertEqual(ForecastRules.barPosition(for: day(low: 3, high: 3), in: 3...3), 0...1)
    }

    func testCompassDirections() {
        XCTAssertEqual(ForecastRules.compassDirection(degrees: 0), "N")
        XCTAssertEqual(ForecastRules.compassDirection(degrees: 44), "NE")
        XCTAssertEqual(ForecastRules.compassDirection(degrees: 200), "S")
        XCTAssertEqual(ForecastRules.compassDirection(degrees: 350), "N")
        XCTAssertEqual(ForecastRules.compassDirection(degrees: -90), "W")
        XCTAssertEqual(ForecastRules.compassDirection(degrees: 720 + 135), "SE")
    }

    func testUVLevels() {
        XCTAssertEqual(ForecastRules.uvLevel(1.4), "Low")
        XCTAssertEqual(ForecastRules.uvLevel(3), "Moderate")
        XCTAssertEqual(ForecastRules.uvLevel(7.9), "High")
        XCTAssertEqual(ForecastRules.uvLevel(10), "Very High")
        XCTAssertEqual(ForecastRules.uvLevel(11.5), "Extreme")
    }

    func testOnlyNotableRainChancesAreShown() {
        XCTAssertNil(ForecastRules.notablePrecipitationChance(nil))
        XCTAssertNil(ForecastRules.notablePrecipitationChance(10))
        XCTAssertEqual(ForecastRules.notablePrecipitationChance(20), 20)
        XCTAssertEqual(ForecastRules.notablePrecipitationChance(85), 85)
    }

    func testFeelsLikeNotes() {
        XCTAssertEqual(ForecastRules.feelsLikeNote(actual: 10, apparent: 6), "Feels colder than the actual temperature.")
        XCTAssertEqual(ForecastRules.feelsLikeNote(actual: 30, apparent: 34), "Feels warmer than the actual temperature.")
        XCTAssertEqual(ForecastRules.feelsLikeNote(actual: 18, apparent: 17), "Similar to the actual temperature.")
    }
}
