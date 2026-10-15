import DesignSystem
import WeatherCore
import XCTest

final class NimbusFormatTests: XCTestCase {
    private let yerevan = TimeZone(identifier: "Asia/Yerevan") ?? .gmt
    private let british = Locale(identifier: "en_GB")
    /// 15 October 2026, 15:00 in Yerevan.
    private let afternoon = Date(timeIntervalSince1970: 1_792_062_000)

    func testTemperaturesRoundAndNeverShowMinusZero() {
        XCTAssertEqual(NimbusFormat.temperature(18.4), "18°")
        XCTAssertEqual(NimbusFormat.temperature(18.6), "19°")
        XCTAssertEqual(NimbusFormat.temperature(-0.3), "0°")
        XCTAssertEqual(NimbusFormat.temperature(-7.8), "-8°")
    }

    func testTimesUseThePlacesTimeZone() {
        XCTAssertEqual(NimbusFormat.time(afternoon, in: yerevan, locale: british), "15:00")
        XCTAssertEqual(NimbusFormat.time(afternoon, in: .gmt, locale: british), "11:00")
        XCTAssertEqual(NimbusFormat.hour(afternoon, in: yerevan, locale: british), "15")
    }

    func testTheFirstDayIsToday() {
        let nextDay = afternoon.addingTimeInterval(24 * 3600)

        XCTAssertEqual(NimbusFormat.weekday(afternoon, in: yerevan, now: afternoon, locale: british), "Today")
        XCTAssertEqual(NimbusFormat.weekday(nextDay, in: yerevan, now: afternoon, locale: british), "Fri")
    }

    func testDetailValues() {
        XCTAssertEqual(NimbusFormat.wind(speed: 11.6, direction: 315), "12 km/h NW")
        XCTAssertEqual(NimbusFormat.percent(64), "64%")
        XCTAssertEqual(NimbusFormat.pressure(1016.3), "1016 hPa")
        XCTAssertEqual(NimbusFormat.highLow(high: 21.3, low: 9.2), "H:21° L:9°")
    }

    func testEverySkyHasAGradient() {
        let skies: [WeatherCondition.Sky] = [.clear, .cloudy, .fog, .rain, .snow, .storm]
        for sky in skies {
            XCTAssertEqual(SkyPalette.colors(for: sky, isDay: true).count, 2)
            XCTAssertEqual(SkyPalette.colors(for: sky, isDay: false).count, 2)
        }
    }
}
