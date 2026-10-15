import WeatherCore
import XCTest

final class WeatherConditionTests: XCTestCase {
    func testWMOCodesMapToConditions() {
        let expected: [Int: WeatherCondition] = [
            0: .clear, 1: .mainlyClear, 2: .partlyCloudy, 3: .overcast, 45: .fog, 48: .fog,
            51: .drizzle, 57: .freezingDrizzle, 63: .rain, 67: .freezingRain, 75: .snow, 77: .snow,
            81: .rainShowers, 86: .snowShowers, 95: .thunderstorm, 99: .thunderstorm,
        ]
        for (code, condition) in expected {
            XCTAssertEqual(WeatherCondition(wmoCode: code), condition, "WMO code \(code)")
        }
    }

    func testUnknownCodesDoNotCrash() {
        XCTAssertEqual(WeatherCondition(wmoCode: -1), .unknown)
        XCTAssertEqual(WeatherCondition(wmoCode: 42), .unknown)
        XCTAssertEqual(WeatherCondition.unknown.sky, .clear)
    }

    func testConditionsGroupIntoSkies() {
        XCTAssertEqual(WeatherCondition.partlyCloudy.sky, .cloudy)
        XCTAssertEqual(WeatherCondition.freezingDrizzle.sky, .rain)
        XCTAssertEqual(WeatherCondition.snowShowers.sky, .snow)
        XCTAssertEqual(WeatherCondition.thunderstorm.sky, .storm)
        XCTAssertEqual(WeatherCondition.fog.sky, .fog)
    }

    func testNightSymbolsUseTheMoon() {
        XCTAssertEqual(WeatherCondition.clear.symbolName(isDay: true), "sun.max.fill")
        XCTAssertEqual(WeatherCondition.clear.symbolName(isDay: false), "moon.stars.fill")
        XCTAssertEqual(WeatherCondition.rainShowers.symbolName(isDay: false), "cloud.moon.rain.fill")
        XCTAssertEqual(WeatherCondition.overcast.symbolName(isDay: false), "cloud.fill")
    }

    func testEveryConditionHasATitleAndASymbol() {
        for condition in WeatherCondition.allCases {
            XCTAssertFalse(condition.title.isEmpty)
            XCTAssertFalse(condition.symbolName().isEmpty)
        }
    }
}
