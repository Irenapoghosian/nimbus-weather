import WeatherCore
import XCTest

final class PlaceTests: XCTestCase {
    func testSubtitleSkipsMissingAndRepeatedParts() {
        XCTAssertEqual(Place(id: "1", name: "Gyumri", region: "Shirak", country: "Armenia", latitude: 0, longitude: 0).subtitle,
                       "Shirak, Armenia")
        XCTAssertEqual(Place(id: "2", name: "Yerevan", region: "Yerevan", country: "Armenia", latitude: 0, longitude: 0).subtitle,
                       "Armenia")
        XCTAssertEqual(Place(id: "3", name: "Somewhere", region: "", latitude: 0, longitude: 0).subtitle, "")
    }

    func testSavedPlacesSurviveARelaunch() throws {
        let suite = "PlaceTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }

        let places = [
            Place(id: "616052", name: "Yerevan", country: "Armenia", latitude: 40.18, longitude: 44.51),
            Place(id: "2988507", name: "Paris", region: "Île-de-France", country: "France", latitude: 48.85, longitude: 2.35),
        ]
        UserDefaultsPlacesStore(defaults: defaults).savePlaces(places)

        XCTAssertEqual(UserDefaultsPlacesStore(defaults: defaults).loadPlaces(), places)
    }

    func testCorruptStorageLoadsAsEmpty() throws {
        let suite = "PlaceTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }

        XCTAssertEqual(UserDefaultsPlacesStore(defaults: defaults).loadPlaces(), [])
        defaults.set(Data("not json".utf8), forKey: UserDefaultsPlacesStore.key)
        XCTAssertEqual(UserDefaultsPlacesStore(defaults: defaults).loadPlaces(), [])
    }

    func testErrorsExplainThemselves() {
        for error in [WeatherError.offline, .unavailable, .locationDenied, .locationUnavailable] {
            XCTAssertFalse(error.message.isEmpty)
        }
    }
}
