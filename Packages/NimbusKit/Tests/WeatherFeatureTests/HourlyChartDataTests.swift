import WeatherCore
@testable import WeatherFeature
import XCTest

final class HourlyChartDataTests: XCTestCase {
    private let start = Date(timeIntervalSince1970: 1_792_044_000)

    private func point(hour: Int, temperature: Double, chance: Double = 0) -> ChartPoint {
        ChartPoint(time: start.addingTimeInterval(Double(hour) * 3600), temperature: temperature, precipitationChance: chance)
    }

    func testPointsCountMissingRainChancesAsZero() {
        let hours = [
            HourlyForecast(time: start, temperature: 14, precipitationChance: nil, condition: .clear, isDay: true),
            HourlyForecast(time: start.addingTimeInterval(3600), temperature: 15, precipitationChance: 40, condition: .rain, isDay: true),
        ]
        let points = HourlyChartData.points(from: hours)

        XCTAssertEqual(points.map(\.precipitationChance), [0, 40])
        XCTAssertEqual(points.map { $0.value(for: .temperature) }, [14, 15])
    }

    func testTemperatureScaleLeavesRoomAroundTheCurve() {
        let points = [point(hour: 0, temperature: 8.4), point(hour: 1, temperature: 19.6)]
        XCTAssertEqual(HourlyChartData.domain(for: .temperature, points: points), 6...22)
    }

    func testAFlatDayIsNotStretched() {
        let points = [point(hour: 0, temperature: 15), point(hour: 1, temperature: 15)]
        let domain = HourlyChartData.domain(for: .temperature, points: points)

        XCTAssertGreaterThanOrEqual(domain.upperBound - domain.lowerBound, 6)
        XCTAssertTrue(domain.contains(15))
    }

    func testRainIsAlwaysOutOfAHundred() {
        XCTAssertEqual(HourlyChartData.domain(for: .precipitation, points: [point(hour: 0, temperature: 1, chance: 30)]), 0...100)
        XCTAssertEqual(HourlyChartData.domain(for: .temperature, points: []), 0...10)
    }

    func testTheNearestHourIsSelected() {
        let points = (0..<24).map { point(hour: $0, temperature: Double($0)) }

        XCTAssertEqual(HourlyChartData.nearest(to: start.addingTimeInterval(3 * 3600 + 1000), in: points)?.temperature, 3)
        XCTAssertEqual(HourlyChartData.nearest(to: start.addingTimeInterval(3 * 3600 + 2600), in: points)?.temperature, 4)
        XCTAssertNil(HourlyChartData.nearest(to: nil, in: points))
    }

    func testLabels() {
        XCTAssertEqual(HourlyChartData.label(17.6, metric: .temperature), "18°")
        XCTAssertEqual(HourlyChartData.label(40, metric: .precipitation), "40%")
        XCTAssertEqual(ChartMetric.allCases.map(\.title), ["Temperature", "Rain"])
    }
}
