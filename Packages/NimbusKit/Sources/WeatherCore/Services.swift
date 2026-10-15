import Foundation

/// Fetches the forecast for a place. `OpenMeteoClient` is the real one.
public protocol ForecastService: Sendable {
    func forecast(for place: Place) async throws -> Forecast
}

/// Finds places by name, for the city search.
public protocol PlaceSearchService: Sendable {
    func searchPlaces(matching query: String) async throws -> [Place]
}

/// "Where am I?", answered as a place with a name.
public protocol LocationProvider: Sendable {
    func currentPlace() async throws -> Place
}

/// The cities the user saved, kept on the device.
public protocol PlacesStore: Sendable {
    func loadPlaces() -> [Place]
    func savePlaces(_ places: [Place])
}

/// Failures the screens know how to explain.
public enum WeatherError: Error, Equatable, Sendable {
    case offline
    case unavailable
    case locationDenied
    case locationUnavailable

    public var message: String {
        switch self {
        case .offline: "You're offline. Check your connection and try again."
        case .unavailable: "The weather service isn't responding right now. Try again in a moment."
        case .locationDenied: "Location access is off. Allow it in Settings, or search for a city."
        case .locationUnavailable: "Your location couldn't be found. Search for a city instead."
        }
    }
}
