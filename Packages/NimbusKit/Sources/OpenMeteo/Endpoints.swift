import Foundation
import WeatherCore

/// The two Open-Meteo URLs the app calls. Both are free and need no API key.
enum Endpoints {
    static let currentFields = [
        "temperature_2m", "relative_humidity_2m", "apparent_temperature", "is_day", "precipitation",
        "weather_code", "wind_speed_10m", "wind_direction_10m", "pressure_msl",
    ]
    static let hourlyFields = ["temperature_2m", "precipitation_probability", "weather_code", "is_day"]
    static let dailyFields = [
        "weather_code", "temperature_2m_max", "temperature_2m_min", "precipitation_probability_max",
        "sunrise", "sunset", "uv_index_max",
    ]

    static func forecast(for place: Place, days: Int = 10) -> URL {
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")
        components?.queryItems = [
            URLQueryItem(name: "latitude", value: coordinate(place.latitude)),
            URLQueryItem(name: "longitude", value: coordinate(place.longitude)),
            URLQueryItem(name: "current", value: currentFields.joined(separator: ",")),
            URLQueryItem(name: "hourly", value: hourlyFields.joined(separator: ",")),
            URLQueryItem(name: "daily", value: dailyFields.joined(separator: ",")),
            // Times come back as Unix seconds, and the place's own time zone is reported.
            URLQueryItem(name: "timeformat", value: "unixtime"),
            URLQueryItem(name: "timezone", value: "auto"),
            URLQueryItem(name: "forecast_days", value: String(days)),
        ]
        return components?.url ?? URL(fileURLWithPath: "/")
    }

    /// Two decimals (about 1 km) is all a forecast needs, and it keeps the exact location on the phone.
    static func coordinate(_ degrees: Double) -> String {
        String(format: "%.2f", locale: Locale(identifier: "en_US_POSIX"), degrees)
    }

    static func search(_ query: String, language: String = "en", count: Int = 10) -> URL {
        var components = URLComponents(string: "https://geocoding-api.open-meteo.com/v1/search")
        components?.queryItems = [
            URLQueryItem(name: "name", value: query),
            URLQueryItem(name: "count", value: String(count)),
            URLQueryItem(name: "language", value: language),
            URLQueryItem(name: "format", value: "json"),
        ]
        return components?.url ?? URL(fileURLWithPath: "/")
    }
}
