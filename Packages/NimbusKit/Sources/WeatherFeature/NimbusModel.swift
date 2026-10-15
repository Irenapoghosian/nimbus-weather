import Foundation
import Observation
import WeatherCore

/// The app's pages (My Location first, then saved cities), which one is showing, and editing the list.
@MainActor
@Observable
public final class NimbusModel {
    public private(set) var pages: [WeatherViewModel] = []
    public var selectedID: String
    public let search: PlaceSearchModel

    @ObservationIgnored private let forecasts: ForecastService
    @ObservationIgnored private let location: LocationProvider
    @ObservationIgnored private let store: PlacesStore
    @ObservationIgnored private let now: () -> Date

    public init(
        forecasts: ForecastService,
        search: PlaceSearchService,
        location: LocationProvider,
        store: PlacesStore,
        now: @escaping () -> Date = { Date() }
    ) {
        self.forecasts = forecasts
        self.location = location
        self.store = store
        self.now = now
        self.search = PlaceSearchModel(service: search)
        let current = WeatherViewModel(source: .currentLocation, forecasts: forecasts, location: location, now: now)
        self.selectedID = current.id
        self.pages = [current] + store.loadPlaces().map { place in
            WeatherViewModel(source: .place(place), forecasts: forecasts, now: now)
        }
    }

    public var savedPlaces: [Place] {
        pages.compactMap { page in
            if case .place(let place) = page.source { return place }
            return nil
        }
    }

    public var selectedPage: WeatherViewModel? {
        pages.first { $0.id == selectedID }
    }

    /// Adds a city (or jumps to it if it's already saved) and shows it.
    public func add(_ place: Place) {
        if !pages.contains(where: { $0.id == place.id }) {
            pages.append(WeatherViewModel(source: .place(place), forecasts: forecasts, now: now))
            store.savePlaces(savedPlaces)
        }
        selectedID = place.id
        search.clear()
    }

    /// Removes saved cities; My Location always stays.
    public func removePlaces(withIDs ids: Set<String>) {
        pages.removeAll { !$0.isCurrentLocation && ids.contains($0.id) }
        if !pages.contains(where: { $0.id == selectedID }) {
            selectedID = pages.first?.id ?? selectedID
        }
        store.savePlaces(savedPlaces)
    }

    /// Removes saved cities by their position in the saved list, as `onDelete` reports them.
    public func removeSavedPlaces(atOffsets offsets: IndexSet) {
        let saved = savedPlaces
        removePlaces(withIDs: Set(offsets.filter(saved.indices.contains).map { saved[$0].id }))
    }

    /// Reorders saved cities; offsets are within the saved list (My Location excluded).
    public func movePlaces(fromOffsets source: IndexSet, toOffset destination: Int) {
        var saved = pages.filter { !$0.isCurrentLocation }
        saved.move(fromOffsets: source, toOffset: destination)
        pages = pages.filter { $0.isCurrentLocation } + saved
        store.savePlaces(savedPlaces)
    }
}
