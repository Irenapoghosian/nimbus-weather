import WeatherCore
@testable import WeatherFeature
import XCTest

@MainActor
final class PlaceSearchModelTests: XCTestCase {
    private let service = FakeSearch()

    private func makeModel() -> PlaceSearchModel {
        PlaceSearchModel(service: service, pause: {})
    }

    func testSearchFindsPlaces() async {
        let model = makeModel()
        model.query = "  Par "

        await model.search()

        XCTAssertTrue(model.isActive)
        XCTAssertEqual(model.results, [Sample.yerevan, Sample.paris])
        XCTAssertEqual(service.queries, ["Par"])
        XCTAssertNil(model.errorMessage)
        XCTAssertFalse(model.isSearching)
    }

    func testAnEmptyQueryClearsResultsWithoutSearching() async {
        let model = makeModel()
        model.query = "Paris"
        await model.search()

        model.query = "   "
        await model.search()

        XCTAssertFalse(model.isActive)
        XCTAssertEqual(model.results, [])
        XCTAssertEqual(service.queries, ["Paris"])
    }

    func testNoMatchesSaysSo() async {
        service.result = .success([])
        let model = makeModel()
        model.query = "Xyzzy"

        await model.search()

        XCTAssertEqual(model.errorMessage, "No results for “Xyzzy”")
    }

    func testFailuresAreExplained() async {
        service.result = .failure(WeatherError.offline)
        let model = makeModel()
        model.query = "Paris"
        await model.search()
        XCTAssertEqual(model.errorMessage, WeatherError.offline.message)

        service.result = .failure(URLError(.badURL))
        await model.search()
        XCTAssertEqual(model.errorMessage, WeatherError.unavailable.message)
        XCTAssertEqual(model.results, [])
    }

    func testTypingAgainCancelsThePendingSearch() async {
        let model = PlaceSearchModel(service: service, pause: { throw CancellationError() })
        model.query = "Pa"

        await model.search()

        XCTAssertTrue(service.queries.isEmpty)
    }

    func testClearResetsEverything() async {
        let model = makeModel()
        model.query = "Paris"
        await model.search()

        model.clear()

        XCTAssertEqual(model.query, "")
        XCTAssertEqual(model.results, [])
        XCTAssertNil(model.errorMessage)
    }
}
