import Foundation
import OSLog
import WeatherCore

/// Forecasts and city search from Open-Meteo, translated into WeatherCore types.
/// HTTP and decoding problems never leak out: callers only see `WeatherError`.
public struct OpenMeteoClient: ForecastService, PlaceSearchService {
    private let http: HTTPClient

    public init(http: HTTPClient = URLSessionHTTPClient()) {
        self.http = http
    }

    public func forecast(for place: Place) async throws -> Forecast {
        let data = try await get(Endpoints.forecast(for: place))
        do {
            let response = try Self.decoder.decode(ForecastResponse.self, from: data)
            return try ForecastMapper.forecast(from: response, for: place)
        } catch {
            Self.log.error("Forecast couldn't be read: \(String(describing: error), privacy: .public)")
            throw WeatherError.unavailable
        }
    }

    public func searchPlaces(matching query: String) async throws -> [Place] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        // The API needs at least two characters to search.
        guard trimmed.count >= 2 else { return [] }
        let data = try await get(Endpoints.search(trimmed))
        do {
            let response = try Self.decoder.decode(GeocodingResponse.self, from: data)
            return (response.results ?? []).map(ForecastMapper.place(from:))
        } catch {
            Self.log.error("Search results couldn't be read: \(String(describing: error), privacy: .public)")
            throw WeatherError.unavailable
        }
    }

    private func get(_ url: URL) async throws -> Data {
        let data: Data
        let response: HTTPURLResponse
        do {
            (data, response) = try await http.data(from: url)
        } catch let error as URLError where Self.offlineCodes.contains(error.code) {
            throw WeatherError.offline
        } catch {
            Self.log.error("Request failed: \(String(describing: error), privacy: .public)")
            throw WeatherError.unavailable
        }
        guard (200..<300).contains(response.statusCode) else {
            Self.log.error("HTTP \(response.statusCode): \(String(decoding: data.prefix(300), as: UTF8.self), privacy: .public)")
            throw WeatherError.unavailable
        }
        return data
    }

    private static let offlineCodes: Set<URLError.Code> = [
        .notConnectedToInternet, .networkConnectionLost, .timedOut, .cannotFindHost, .cannotConnectToHost,
        .dataNotAllowed, .internationalRoamingOff,
    ]

    /// Keys are mapped by each DTO's `CodingKeys`.
    static let decoder = JSONDecoder()

    private static let log = Logger(subsystem: "com.irenapoghosyan.nimbus", category: "OpenMeteo")
}
