import Foundation

/// A city (or the user's location) to show the weather for.
public struct Place: Codable, Hashable, Identifiable, Sendable {
    public let id: String
    public let name: String
    /// State, province or region, e.g. "California".
    public let region: String?
    public let country: String?
    public let latitude: Double
    public let longitude: Double

    public init(id: String, name: String, region: String? = nil, country: String? = nil, latitude: Double, longitude: Double) {
        self.id = id
        self.name = name
        self.region = region
        self.country = country
        self.latitude = latitude
        self.longitude = longitude
    }

    /// "California, United States", "Armenia", or "" when nothing is known.
    public var subtitle: String {
        [region, country]
            .compactMap { $0 }
            .filter { !$0.isEmpty && $0 != name }
            .joined(separator: ", ")
    }
}
