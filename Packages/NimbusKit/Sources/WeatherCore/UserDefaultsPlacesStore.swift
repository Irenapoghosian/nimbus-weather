import Foundation

/// Saved cities as JSON in `UserDefaults`: a short list that has to survive relaunches, nothing more.
public final class UserDefaultsPlacesStore: PlacesStore, @unchecked Sendable {
    public static let key = "savedPlaces"
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func loadPlaces() -> [Place] {
        guard let data = defaults.data(forKey: Self.key) else { return [] }
        return (try? JSONDecoder().decode([Place].self, from: data)) ?? []
    }

    public func savePlaces(_ places: [Place]) {
        guard let data = try? JSONEncoder().encode(places) else { return }
        defaults.set(data, forKey: Self.key)
    }
}
