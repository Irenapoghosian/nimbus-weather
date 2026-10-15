import LocationKit
import OpenMeteo
import WeatherCore
import WeatherFeature

/// The composition root: the only place that knows Open-Meteo, Core Location and UserDefaults.
@MainActor
final class AppContainer {
    let model: NimbusModel

    init(forecasts: ForecastService, search: PlaceSearchService, location: LocationProvider, store: PlacesStore) {
        model = NimbusModel(forecasts: forecasts, search: search, location: location, store: store)
    }

    static func live() -> AppContainer {
        // One client answers both forecasts and city search.
        let openMeteo = OpenMeteoClient()
        return AppContainer(
            forecasts: openMeteo,
            search: openMeteo,
            location: DeviceLocationProvider(),
            store: UserDefaultsPlacesStore()
        )
    }
}
