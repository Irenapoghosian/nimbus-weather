import WeatherCore
@testable import WeatherFeature
import XCTest

@MainActor
final class NimbusModelTests: XCTestCase {
    private let store = InMemoryPlacesStore([Sample.yerevan, Sample.paris])

    private func makeModel() -> NimbusModel {
        NimbusModel(forecasts: FakeForecasts(), search: FakeSearch(), location: FakeLocation(), store: store, now: { Sample.now })
    }

    func testMyLocationComesFirstThenSavedCities() {
        let model = makeModel()

        XCTAssertEqual(model.pages.map { $0.id }, ["current-location", "616052", "2988507"])
        XCTAssertEqual(model.savedPlaces, [Sample.yerevan, Sample.paris])
        XCTAssertEqual(model.selectedID, "current-location")
        XCTAssertTrue(model.selectedPage?.isCurrentLocation == true)
    }

    func testAddingACitySavesAndShowsIt() {
        let model = makeModel()
        model.search.query = "Tok"

        model.add(Sample.tokyo)

        XCTAssertEqual(model.savedPlaces, [Sample.yerevan, Sample.paris, Sample.tokyo])
        XCTAssertEqual(store.places, model.savedPlaces)
        XCTAssertEqual(model.selectedID, Sample.tokyo.id)
        XCTAssertEqual(model.search.query, "")
    }

    func testAddingASavedCityJumpsToIt() {
        let model = makeModel()

        model.add(Sample.paris)

        XCTAssertEqual(model.pages.count, 3)
        XCTAssertEqual(model.selectedID, Sample.paris.id)
        XCTAssertEqual(store.saveCount, 0)
    }

    func testRemovingTheShownCitySelectsMyLocation() {
        let model = makeModel()
        model.selectedID = Sample.paris.id

        model.removeSavedPlaces(atOffsets: [1])

        XCTAssertEqual(model.savedPlaces, [Sample.yerevan])
        XCTAssertEqual(store.places, [Sample.yerevan])
        XCTAssertEqual(model.selectedID, "current-location")
    }

    func testMyLocationCannotBeRemoved() {
        let model = makeModel()

        model.removePlaces(withIDs: ["current-location", Sample.yerevan.id])
        model.removeSavedPlaces(atOffsets: [7])

        XCTAssertEqual(model.pages.map { $0.id }, ["current-location", Sample.paris.id])
    }

    func testReorderingIsSaved() {
        let model = makeModel()

        model.movePlaces(fromOffsets: [1], toOffset: 0)

        XCTAssertEqual(model.savedPlaces, [Sample.paris, Sample.yerevan])
        XCTAssertEqual(store.places, [Sample.paris, Sample.yerevan])
        XCTAssertTrue(model.pages.first?.isCurrentLocation == true)
    }
}
