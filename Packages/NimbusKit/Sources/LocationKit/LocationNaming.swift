import Foundation
import WeatherCore

/// Builds the "My Location" place from a reverse-geocoded placemark.
public enum LocationNaming {
    /// The ID that marks the place as the device's location rather than a saved city.
    public static let currentLocationID = "current-location"

    public static func place(
        latitude: Double,
        longitude: Double,
        locality: String?,
        region: String?,
        country: String?
    ) -> Place {
        Place(
            id: currentLocationID,
            name: locality ?? region ?? "My Location",
            region: locality == nil ? nil : region,
            country: country,
            latitude: latitude,
            longitude: longitude
        )
    }
}
