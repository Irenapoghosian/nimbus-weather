@testable import OpenMeteo
import WeatherCore
import XCTest

final class DecodingTests: XCTestCase {
    private let utcPlusFour = 4 * 3600

    func testTimesDecodeFromUnixSecondsAndLocalStrings() throws {
        let json = #"[1792033920, "2026-10-15T07:12", "2026-10-15"]"#
        let times = try OpenMeteoClient.decoder.decode([APITime].self, from: Data(json.utf8))

        XCTAssertEqual(times[0].date(utcOffset: utcPlusFour), Fixtures.sunrise)
        // A local "07:12" in UTC+4 is the same moment as the Unix time above.
        XCTAssertEqual(times[1].date(utcOffset: utcPlusFour), Fixtures.sunrise)
        XCTAssertEqual(times[2].date(utcOffset: utcPlusFour), Fixtures.today)
    }

    func testColumnsOfDifferentLengthsAreTrimmedInsteadOfCrashing() throws {
        let json = """
        {
          "utc_offset_seconds": 0,
          "current": { "time": 1792044900, "temperature_2m": 5 },
          "hourly": { "time": [1792040400, 1792044000, 1792047600], "temperature_2m": [1], "weather_code": [] },
          "daily": { "time": [1792008000], "weather_code": [null], "temperature_2m_max": [6], "temperature_2m_min": [] }
        }
        """
        let response = try OpenMeteoClient.decoder.decode(ForecastResponse.self, from: Data(json.utf8))
        let place = Place(id: "x", name: "Nowhere", latitude: 0, longitude: 0)
        let forecast = try ForecastMapper.forecast(from: response, for: place)

        XCTAssertEqual(forecast.hourly.count, 1)
        XCTAssertEqual(forecast.hourly.first?.condition, .unknown)
        XCTAssertEqual(forecast.daily, [])
        XCTAssertEqual(forecast.timeZone.secondsFromGMT(), 0)
        // Missing current fields fall back to sensible values.
        XCTAssertEqual(forecast.current.apparentTemperature, 5)
        XCTAssertTrue(forecast.current.isDay)
    }

    func testCoordinatesAreSentWithTwoDecimals() {
        XCTAssertEqual(Endpoints.coordinate(40.181_11), "40.18")
        XCTAssertEqual(Endpoints.coordinate(-0.125_74), "-0.13")
    }
}
