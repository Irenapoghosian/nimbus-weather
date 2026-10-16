import Foundation

/// A place written as text, for the two places that can only hold strings: a widget's saved
/// configuration and the `nimbus://` link a widget opens.
public enum PlaceLink {
    public static let scheme = "nimbus"

    /// The place as compact JSON; stable for the same place.
    public static func code(for place: Place) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        guard let data = try? encoder.encode(place) else { return place.id }
        return String(bytes: data, encoding: .utf8) ?? place.id
    }

    public static func place(fromCode code: String) -> Place? {
        try? JSONDecoder().decode(Place.self, from: Data(code.utf8))
    }

    /// `nimbus://place?code=…`
    public static func url(for place: Place) -> URL? {
        var components = URLComponents()
        components.scheme = scheme
        components.host = "place"
        components.queryItems = [URLQueryItem(name: "code", value: code(for: place))]
        return components.url
    }

    public static func place(from url: URL) -> Place? {
        guard
            url.scheme == scheme,
            url.host == "place",
            let code = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first(where: { $0.name == "code" })?.value
        else { return nil }
        return place(fromCode: code)
    }
}
