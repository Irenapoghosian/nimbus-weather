import LocationKit
import XCTest

final class LocationNamingTests: XCTestCase {
    func testTheCityNamesTheLocation() {
        let place = LocationNaming.place(latitude: 40.18, longitude: 44.51, locality: "Yerevan", region: "Yerevan", country: "Armenia")

        XCTAssertEqual(place.id, LocationNaming.currentLocationID)
        XCTAssertEqual(place.name, "Yerevan")
        XCTAssertEqual(place.subtitle, "Armenia")
        XCTAssertEqual(place.latitude, 40.18)
    }

    func testTheRegionIsUsedOutsideCities() {
        let place = LocationNaming.place(latitude: 40.5, longitude: 44.9, locality: nil, region: "Kotayk", country: "Armenia")

        XCTAssertEqual(place.name, "Kotayk")
        XCTAssertNil(place.region)
        XCTAssertEqual(place.subtitle, "Armenia")
    }

    func testWithoutAPlacemarkItIsMyLocation() {
        let place = LocationNaming.place(latitude: 0, longitude: 0, locality: nil, region: nil, country: nil)

        XCTAssertEqual(place.name, "My Location")
        XCTAssertEqual(place.subtitle, "")
    }
}
