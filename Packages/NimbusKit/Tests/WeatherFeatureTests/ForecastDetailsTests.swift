import WeatherCore
@testable import WeatherFeature
import XCTest

final class ForecastDetailsTests: XCTestCase {
    private let british = Locale(identifier: "en_GB")

    func testDetailsForAFullForecast() {
        let items = ForecastDetails.items(for: Sample.forecast(for: Sample.yerevan), locale: british)

        XCTAssertEqual(items.map(\.title), ["Feels like", "Humidity", "Wind", "Pressure", "UV index", "Sunrise"])
        XCTAssertEqual(items.map(\.value).prefix(5), ["15°", "64%", "12 km/h NW", "1016 hPa", "4"])
        // "7:12" or "07:12" depending on the OS version's British format, so only the digits are checked.
        XCTAssertTrue(items[5].value.hasSuffix("7:12"), items[5].value)
        XCTAssertEqual(items[0].footnote, "Feels colder than the actual temperature.")
        XCTAssertEqual(items[4].footnote, "Moderate")
        XCTAssertEqual(items[5].footnote, "Sunset: 18:31")
    }

    func testMissingUVIsLeftOut() {
        let items = ForecastDetails.items(for: Sample.forecast(for: Sample.yerevan, uvIndex: nil), locale: british)
        XCTAssertFalse(items.map(\.title).contains("UV index"))
    }
}
