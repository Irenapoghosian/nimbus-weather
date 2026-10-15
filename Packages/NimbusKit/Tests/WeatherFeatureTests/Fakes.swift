import Foundation
import WeatherCore

enum Sample {
    static let now = Date(timeIntervalSince1970: 1_792_044_900)
    static let yerevan = Place(id: "616052", name: "Yerevan", country: "Armenia", latitude: 40.18, longitude: 44.51)
    static let paris = Place(id: "2988507", name: "Paris", region: "Île-de-France", country: "France", latitude: 48.85, longitude: 2.35)
    static let tokyo = Place(id: "1850147", name: "Tokyo", country: "Japan", latitude: 35.69, longitude: 139.69)
    static let here = Place(id: "current-location", name: "Gyumri", region: "Shirak", country: "Armenia", latitude: 40.79, longitude: 43.85)

    static func forecast(for place: Place, temperature: Double = 18, uvIndex: Double? = 4.2) -> Forecast {
        let midnight = now.addingTimeInterval(-10 * 3600 - 15 * 60)
        return Forecast(
            place: place,
            timeZone: TimeZone(identifier: "Asia/Yerevan") ?? .gmt,
            current: CurrentConditions(
                time: now,
                temperature: temperature,
                apparentTemperature: temperature - 3,
                humidity: 64,
                precipitation: 0,
                windSpeed: 11.6,
                windDirection: 315,
                pressure: 1016.3,
                condition: .partlyCloudy,
                isDay: true
            ),
            hourly: (0..<48).map { index in
                HourlyForecast(
                    time: midnight.addingTimeInterval(Double(index) * 3600),
                    temperature: 10 + Double(index % 12),
                    precipitationChance: index * 2,
                    condition: .clear,
                    isDay: (7...18).contains(index % 24)
                )
            },
            daily: (0..<10).map { index in
                DailyForecast(
                    date: midnight.addingTimeInterval(Double(index) * 86_400),
                    high: 21 - Double(index),
                    low: 9 - Double(index),
                    precipitationChance: 10 * index,
                    condition: .rain,
                    sunrise: midnight.addingTimeInterval(7 * 3600 + 12 * 60),
                    sunset: midnight.addingTimeInterval(18 * 3600 + 31 * 60),
                    uvIndexMax: uvIndex
                )
            }
        )
    }
}

/// A forecast service whose answers the test controls, counting the requests it gets.
final class FakeForecasts: ForecastService, @unchecked Sendable {
    var error: WeatherError?
    var temperature: Double = 18
    private(set) var requestedPlaces: [Place] = []

    func forecast(for place: Place) async throws -> Forecast {
        requestedPlaces.append(place)
        if let error { throw error }
        return Sample.forecast(for: place, temperature: temperature)
    }
}

final class FakeLocation: LocationProvider, @unchecked Sendable {
    var result: Result<Place, WeatherError> = .success(Sample.here)

    func currentPlace() async throws -> Place {
        try result.get()
    }
}

final class FakeSearch: PlaceSearchService, @unchecked Sendable {
    var result: Result<[Place], Error> = .success([Sample.yerevan, Sample.paris])
    private(set) var queries: [String] = []

    func searchPlaces(matching query: String) async throws -> [Place] {
        queries.append(query)
        return try result.get()
    }
}

final class InMemoryPlacesStore: PlacesStore, @unchecked Sendable {
    var places: [Place]
    private(set) var saveCount = 0

    init(_ places: [Place] = []) {
        self.places = places
    }

    func loadPlaces() -> [Place] { places }

    func savePlaces(_ places: [Place]) {
        self.places = places
        saveCount += 1
    }
}

/// A clock the test can move forward.
final class TestClock: @unchecked Sendable {
    var now = Sample.now

    func advance(by seconds: TimeInterval) {
        now = now.addingTimeInterval(seconds)
    }
}
