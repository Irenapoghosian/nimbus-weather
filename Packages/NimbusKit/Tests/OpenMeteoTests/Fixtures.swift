import Foundation
import OpenMeteo

/// Trimmed Open-Meteo responses for Yerevan (UTC+4), 15 October 2026.
enum Fixtures {
    /// 10:15 local on 15 October.
    static let currentTime = Date(timeIntervalSince1970: 1_792_044_900)
    /// Midnight local on 15 October.
    static let today = Date(timeIntervalSince1970: 1_792_008_000)
    /// 07:12 local on 15 October.
    static let sunrise = Date(timeIntervalSince1970: 1_792_033_920)

    static let forecast = """
    {
      "latitude": 40.18, "longitude": 44.52, "generationtime_ms": 0.21,
      "utc_offset_seconds": 14400, "timezone": "Asia/Yerevan", "timezone_abbreviation": "GMT+4",
      "elevation": 989.0,
      "current": {
        "time": 1792044900, "interval": 900,
        "temperature_2m": 18.4, "relative_humidity_2m": 52, "apparent_temperature": 16.9,
        "is_day": 1, "precipitation": 0.0, "weather_code": 2,
        "wind_speed_10m": 11.2, "wind_direction_10m": 315, "pressure_msl": 1016.3
      },
      "hourly": {
        "time": [1792040400, 1792044000, 1792047600],
        "temperature_2m": [17.1, null, 19.6],
        "precipitation_probability": [10, 15, 40],
        "weather_code": [1, 2, 61],
        "is_day": [1, 1, 1]
      },
      "daily": {
        "time": [1792008000, 1792094400],
        "weather_code": [2, 63],
        "temperature_2m_max": [21.3, 16.0],
        "temperature_2m_min": [9.2, 8.4],
        "precipitation_probability_max": [15, 80],
        "sunrise": [1792033920, 1792120380],
        "sunset": [1792074660, 1792160940],
        "uv_index_max": [4.15, 2.3]
      }
    }
    """

    static let search = """
    {
      "results": [
        { "id": 616052, "name": "Yerevan", "latitude": 40.18111, "longitude": 44.51361,
          "country": "Armenia", "admin1": "Yerevan", "country_code": "AM", "timezone": "Asia/Yerevan" },
        { "id": 5128581, "name": "New York", "latitude": 40.71427, "longitude": -74.00597,
          "country": "United States", "admin1": "New York" },
        { "id": 2643743, "name": "London", "latitude": 51.50853, "longitude": -0.12574 }
      ],
      "generationtime_ms": 0.7
    }
    """

    static let noResults = #"{ "generationtime_ms": 0.4 }"#
}

/// Answers every request with the same canned response, and records the URLs asked for.
final class StubHTTPClient: HTTPClient, @unchecked Sendable {
    private let result: Result<(Data, Int), Error>
    private(set) var requestedURLs: [URL] = []

    init(json: String, status: Int = 200) {
        result = .success((Data(json.utf8), status))
    }

    init(error: Error) {
        result = .failure(error)
    }

    func data(from url: URL) async throws -> (Data, HTTPURLResponse) {
        requestedURLs.append(url)
        let (data, status) = try result.get()
        guard let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil) else {
            throw URLError(.badServerResponse)
        }
        return (data, response)
    }
}

func queryItems(of url: URL?) -> [String: String] {
    guard let url, let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems else { return [:] }
    return Dictionary(items.map { ($0.name, $0.value ?? "") }, uniquingKeysWith: { first, _ in first })
}
