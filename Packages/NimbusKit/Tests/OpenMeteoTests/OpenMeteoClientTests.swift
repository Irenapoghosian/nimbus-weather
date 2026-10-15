@testable import OpenMeteo
import WeatherCore
import XCTest

final class OpenMeteoClientTests: XCTestCase {
    private let yerevan = Place(id: "616052", name: "Yerevan", country: "Armenia", latitude: 40.181_11, longitude: 44.513_61)

    func testForecastMapsCurrentConditions() async throws {
        let forecast = try await OpenMeteoClient(http: StubHTTPClient(json: Fixtures.forecast)).forecast(for: yerevan)

        XCTAssertEqual(forecast.place, yerevan)
        XCTAssertEqual(forecast.timeZone.identifier, "Asia/Yerevan")
        XCTAssertEqual(forecast.current.time, Fixtures.currentTime)
        XCTAssertEqual(forecast.current.temperature, 18.4)
        XCTAssertEqual(forecast.current.apparentTemperature, 16.9)
        XCTAssertEqual(forecast.current.humidity, 52)
        XCTAssertEqual(forecast.current.windDirection, 315)
        XCTAssertEqual(forecast.current.pressure, 1016.3)
        XCTAssertEqual(forecast.current.condition, .partlyCloudy)
        XCTAssertTrue(forecast.current.isDay)
    }

    func testForecastSkipsHoursWithoutATemperature() async throws {
        let forecast = try await OpenMeteoClient(http: StubHTTPClient(json: Fixtures.forecast)).forecast(for: yerevan)

        XCTAssertEqual(forecast.hourly.map(\.temperature), [17.1, 19.6])
        XCTAssertEqual(forecast.hourly.map(\.precipitationChance), [10, 40])
        XCTAssertEqual(forecast.hourly.last?.condition, .rain)
    }

    func testForecastMapsDays() async throws {
        let forecast = try await OpenMeteoClient(http: StubHTTPClient(json: Fixtures.forecast)).forecast(for: yerevan)

        XCTAssertEqual(forecast.daily.count, 2)
        XCTAssertEqual(forecast.today?.date, Fixtures.today)
        XCTAssertEqual(forecast.today?.high, 21.3)
        XCTAssertEqual(forecast.today?.low, 9.2)
        XCTAssertEqual(forecast.today?.sunrise, Fixtures.sunrise)
        XCTAssertEqual(forecast.today?.uvIndexMax, 4.15)
        XCTAssertEqual(forecast.daily.last?.precipitationChance, 80)
        XCTAssertEqual(forecast.daily.last?.condition, .rain)
    }

    func testForecastRequestUsesUnixTimeTheLocalTimeZoneAndRoundedCoordinates() async throws {
        let http = StubHTTPClient(json: Fixtures.forecast)
        _ = try await OpenMeteoClient(http: http).forecast(for: yerevan)

        let query = queryItems(of: http.requestedURLs.first)
        XCTAssertEqual(http.requestedURLs.first?.host, "api.open-meteo.com")
        XCTAssertEqual(query["latitude"], "40.18")
        XCTAssertEqual(query["longitude"], "44.51")
        XCTAssertEqual(query["timeformat"], "unixtime")
        XCTAssertEqual(query["timezone"], "auto")
        XCTAssertEqual(query["forecast_days"], "10")
        XCTAssertTrue(query["current"]?.contains("weather_code") == true)
        XCTAssertTrue(query["daily"]?.contains("uv_index_max") == true)
    }

    func testSearchMapsResults() async throws {
        let places = try await OpenMeteoClient(http: StubHTTPClient(json: Fixtures.search)).searchPlaces(matching: "Yer")

        XCTAssertEqual(places.map(\.id), ["616052", "5128581", "2643743"])
        XCTAssertEqual(places[0].subtitle, "Armenia")
        // The region is dropped when it repeats the city's name.
        XCTAssertEqual(places[1].subtitle, "United States")
        XCTAssertEqual(places[2].subtitle, "")
        XCTAssertEqual(places[1].longitude, -74.005_97)
    }

    func testSearchWithNoMatchesIsEmpty() async throws {
        let places = try await OpenMeteoClient(http: StubHTTPClient(json: Fixtures.noResults)).searchPlaces(matching: "Xyzzy")
        XCTAssertEqual(places, [])
    }

    func testShortQueriesDoNotHitTheNetwork() async throws {
        let http = StubHTTPClient(json: Fixtures.search)
        let places = try await OpenMeteoClient(http: http).searchPlaces(matching: "  a ")

        XCTAssertEqual(places, [])
        XCTAssertTrue(http.requestedURLs.isEmpty)
    }

    func testSearchSendsTheTrimmedName() async throws {
        let http = StubHTTPClient(json: Fixtures.search)
        _ = try await OpenMeteoClient(http: http).searchPlaces(matching: " New York ")

        XCTAssertEqual(http.requestedURLs.first?.host, "geocoding-api.open-meteo.com")
        XCTAssertEqual(queryItems(of: http.requestedURLs.first)["name"], "New York")
    }

    func testNoConnectionIsReportedAsOffline() async {
        let client = OpenMeteoClient(http: StubHTTPClient(error: URLError(.notConnectedToInternet)))
        await assertThrows(.offline) { _ = try await client.forecast(for: self.yerevan) }
    }

    func testOtherFailuresAreReportedAsUnavailable() async {
        let serverError = OpenMeteoClient(http: StubHTTPClient(json: "{}", status: 500))
        await assertThrows(.unavailable) { _ = try await serverError.forecast(for: self.yerevan) }

        let malformed = OpenMeteoClient(http: StubHTTPClient(json: #"{ "current": 1, "results": 1 }"#))
        await assertThrows(.unavailable) { _ = try await malformed.forecast(for: self.yerevan) }
        await assertThrows(.unavailable) { _ = try await malformed.searchPlaces(matching: "Paris") }

        let badCertificate = OpenMeteoClient(http: StubHTTPClient(error: URLError(.serverCertificateUntrusted)))
        await assertThrows(.unavailable) { _ = try await badCertificate.searchPlaces(matching: "Paris") }
    }

    private func assertThrows(
        _ expected: WeatherError,
        file: StaticString = #filePath,
        line: UInt = #line,
        _ body: () async throws -> Void
    ) async {
        do {
            try await body()
            XCTFail("Expected \(expected)", file: file, line: line)
        } catch {
            XCTAssertEqual(error as? WeatherError, expected, file: file, line: line)
        }
    }
}
