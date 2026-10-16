import Foundation
import Observation
import WeatherCore

/// One page: the forecast for a saved city, or for wherever the user is.
@MainActor
@Observable
public final class WeatherViewModel: Identifiable {
    public enum Source: Equatable {
        case currentLocation
        case place(Place)
    }

    public enum State: Equatable {
        case loading
        case loaded(Forecast)
        case failed(WeatherError)
    }

    public let id: String
    public let source: Source
    public private(set) var state = State.loading
    public private(set) var isRefreshing = false
    /// When the shown forecast was fetched.
    public private(set) var lastUpdated: Date?

    @ObservationIgnored private var isFetching = false

    @ObservationIgnored private let forecasts: ForecastService
    @ObservationIgnored private let location: LocationProvider?
    @ObservationIgnored private let now: () -> Date

    public init(
        source: Source,
        forecasts: ForecastService,
        location: LocationProvider? = nil,
        now: @escaping () -> Date = { Date() }
    ) {
        self.source = source
        self.forecasts = forecasts
        self.location = location
        self.now = now
        switch source {
        case .currentLocation: id = "current-location"
        case .place(let place): id = place.id
        }
    }

    public var isCurrentLocation: Bool { source == .currentLocation }

    public var forecast: Forecast? {
        if case .loaded(let forecast) = state { return forecast }
        return nil
    }

    /// The city name once known: "My Location" until Core Location answers.
    public var title: String {
        if let forecast { return forecast.place.name }
        if case .place(let place) = source { return place.name }
        return "My Location"
    }

    /// Under the name in the city list: "California, United States", "My Location" once the city is known,
    /// or "Location unavailable" when Core Location can't help.
    public var subtitle: String {
        switch source {
        case .place(let place):
            return place.subtitle
        case .currentLocation:
            if forecast != nil { return "My Location" }
            if case .failed(let error) = state, error == .locationDenied || error == .locationUnavailable {
                return "Location unavailable"
            }
            return ""
        }
    }

    /// The next 24 hours, starting now.
    public var upcomingHours: [HourlyForecast] {
        guard let forecast else { return [] }
        return ForecastRules.upcomingHours(forecast.hourly, from: now())
    }

    public var currentTime: Date { now() }

    /// Loads once; later calls keep the shown forecast and refresh it quietly.
    public func load() async {
        if forecast == nil { state = .loading }
        await fetch()
    }

    /// Loads unless a fresh forecast is already shown or a request is running.
    /// Called when a page or a list row appears, and when the app comes back to the foreground.
    public func loadIfNeeded(maxAge: TimeInterval = 10 * 60) async {
        guard !isFetching else { return }
        if forecast != nil, let lastUpdated, now().timeIntervalSince(lastUpdated) < maxAge { return }
        await load()
    }

    /// Pull to refresh.
    public func refresh() async {
        isRefreshing = true
        await fetch()
        isRefreshing = false
    }

    private func fetch() async {
        isFetching = true
        defer { isFetching = false }
        do {
            let place = try await resolvePlace()
            state = .loaded(try await forecasts.forecast(for: place))
            lastUpdated = now()
        } catch let error as WeatherError {
            // Keep a forecast that is already on screen; only show errors when there is nothing else.
            if forecast == nil { state = .failed(error) }
        } catch {
            if forecast == nil { state = .failed(.unavailable) }
        }
    }

    private func resolvePlace() async throws -> Place {
        switch source {
        case .place(let place):
            return place
        case .currentLocation:
            guard let location else { throw WeatherError.locationUnavailable }
            return try await location.currentPlace()
        }
    }
}
