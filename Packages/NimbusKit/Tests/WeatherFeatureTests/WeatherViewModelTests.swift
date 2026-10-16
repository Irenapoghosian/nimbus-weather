import WeatherCore
@testable import WeatherFeature
import XCTest

@MainActor
final class WeatherViewModelTests: XCTestCase {
    private let forecasts = FakeForecasts()
    private let clock = TestClock()

    private func makePage(_ source: WeatherViewModel.Source, location: LocationProvider? = FakeLocation()) -> WeatherViewModel {
        let clock = clock
        return WeatherViewModel(source: source, forecasts: forecasts, location: location, now: { clock.now })
    }

    func testLoadingASavedCity() async {
        let page = makePage(.place(Sample.paris))
        XCTAssertEqual(page.state, .loading)
        XCTAssertEqual(page.title, "Paris")
        XCTAssertEqual(page.subtitle, "Île-de-France, France")

        await page.load()

        XCTAssertEqual(page.forecast?.place, Sample.paris)
        XCTAssertEqual(page.lastUpdated, Sample.now)
        XCTAssertEqual(forecasts.requestedPlaces, [Sample.paris])
    }

    func testMyLocationIsNamedOnceFound() async {
        let page = makePage(.currentLocation)
        XCTAssertEqual(page.id, "current-location")
        XCTAssertEqual(page.title, "My Location")
        XCTAssertEqual(page.subtitle, "")

        await page.load()

        XCTAssertEqual(page.title, "Gyumri")
        XCTAssertEqual(page.subtitle, "My Location")
        XCTAssertEqual(forecasts.requestedPlaces, [Sample.here])
    }

    func testDeniedLocationIsExplained() async {
        let location = FakeLocation()
        location.result = .failure(.locationDenied)
        let page = makePage(.currentLocation, location: location)

        await page.load()

        XCTAssertEqual(page.state, .failed(.locationDenied))
        XCTAssertEqual(page.subtitle, "Location unavailable")
        XCTAssertTrue(forecasts.requestedPlaces.isEmpty)
    }

    func testMyLocationWithoutAProviderFails() async {
        let page = makePage(.currentLocation, location: nil)
        await page.load()
        XCTAssertEqual(page.state, .failed(.locationUnavailable))
    }

    func testAFailedRefreshKeepsTheForecastOnScreen() async {
        let page = makePage(.place(Sample.paris))
        await page.load()

        forecasts.error = .offline
        await page.refresh()

        XCTAssertNotNil(page.forecast)
        XCTAssertFalse(page.isRefreshing)
    }

    func testErrorsShowWhenThereIsNothingElse() async {
        forecasts.error = .offline
        let page = makePage(.place(Sample.paris))

        await page.load()
        XCTAssertEqual(page.state, .failed(.offline))

        forecasts.error = nil
        await page.load()
        XCTAssertNotNil(page.forecast)
    }

    func testRefreshReplacesTheForecast() async {
        let page = makePage(.place(Sample.paris))
        await page.load()

        forecasts.temperature = 25
        clock.advance(by: 60)
        await page.refresh()

        XCTAssertEqual(page.forecast?.current.temperature, 25)
        XCTAssertEqual(page.lastUpdated, Sample.now.addingTimeInterval(60))
    }

    func testLoadIfNeededSkipsAFreshForecast() async {
        let page = makePage(.place(Sample.paris))
        await page.loadIfNeeded()
        clock.advance(by: 5 * 60)
        await page.loadIfNeeded()
        XCTAssertEqual(forecasts.requestedPlaces.count, 1)

        clock.advance(by: 6 * 60)
        await page.loadIfNeeded()
        XCTAssertEqual(forecasts.requestedPlaces.count, 2)
    }

    func testLoadIfNeededRetriesAfterAnError() async {
        forecasts.error = .unavailable
        let page = makePage(.place(Sample.paris))
        await page.loadIfNeeded()
        forecasts.error = nil
        await page.loadIfNeeded()

        XCTAssertNotNil(page.forecast)
    }

    func testUpcomingHoursStartAtTheCurrentHour() async {
        let page = makePage(.place(Sample.paris))
        XCTAssertEqual(page.upcomingHours, [])

        await page.load()

        XCTAssertEqual(page.upcomingHours.count, 24)
        // `Sample.now` is 10:15, so the first hour is 10:00.
        XCTAssertEqual(page.upcomingHours.first?.time, Sample.now.addingTimeInterval(-15 * 60))
        XCTAssertEqual(page.currentTime, Sample.now)
    }
}
