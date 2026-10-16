import AppIntents
import WeatherCore
import WidgetFeature

/// A city the user can pick when editing a widget. The whole place is kept in the ID,
/// so the widget can fetch its forecast without asking the app.
struct CityEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "City"
    static var defaultQuery = CityQuery()

    let id: String
    let place: Place

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(place.name)", subtitle: "\(place.subtitle)")
    }

    init(place: Place) {
        self.place = place
        self.id = PlaceLink.code(for: place)
    }
}

/// Suggests a few world cities and searches Open-Meteo for any other, with the app's client.
struct CityQuery: EntityStringQuery {
    func entities(for identifiers: [CityEntity.ID]) async throws -> [CityEntity] {
        identifiers.compactMap(PlaceLink.place(fromCode:)).map(CityEntity.init(place:))
    }

    func entities(matching string: String) async throws -> [CityEntity] {
        try await WidgetDependencies.openMeteo.searchPlaces(matching: string).map(CityEntity.init(place:))
    }

    func suggestedEntities() async throws -> [CityEntity] {
        WidgetDefaults.suggestedCities.map(CityEntity.init(place:))
    }
}

struct SelectCityIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Choose a city"
    static var description = IntentDescription("Pick the city this widget shows.")

    @Parameter(title: "City")
    var city: CityEntity?

    /// Yerevan until the user picks another city.
    var place: Place { city?.place ?? WidgetDefaults.city }
}
