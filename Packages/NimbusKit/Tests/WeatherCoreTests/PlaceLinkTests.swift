import WeatherCore
import XCTest

final class PlaceLinkTests: XCTestCase {
    private let paris = Place(id: "2988507", name: "Paris", region: "Île-de-France", country: "France", latitude: 48.85, longitude: 2.35)

    func testCodesRoundTrip() {
        let code = PlaceLink.code(for: paris)

        XCTAssertEqual(PlaceLink.place(fromCode: code), paris)
        XCTAssertEqual(code, PlaceLink.code(for: paris), "the same place always gets the same code")
        XCTAssertNil(PlaceLink.place(fromCode: "not a place"))
    }

    func testLinksRoundTrip() throws {
        let url = try XCTUnwrap(PlaceLink.url(for: paris))

        XCTAssertEqual(url.scheme, "nimbus")
        XCTAssertEqual(url.host, "place")
        XCTAssertEqual(PlaceLink.place(from: url), paris)
    }

    func testOtherLinksAreIgnored() throws {
        XCTAssertNil(PlaceLink.place(from: try XCTUnwrap(URL(string: "https://open-meteo.com/place?code=x"))))
        XCTAssertNil(PlaceLink.place(from: try XCTUnwrap(URL(string: "nimbus://settings"))))
        XCTAssertNil(PlaceLink.place(from: try XCTUnwrap(URL(string: "nimbus://place"))))
    }
}
