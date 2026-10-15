import Foundation

/// A time from Open-Meteo: Unix seconds (with `timeformat=unixtime`), or an ISO local
/// time such as "2026-10-15T07:12" that some fields still use. Both are decoded.
struct APITime: Decodable, Equatable {
    let seconds: Double?
    let local: String?

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let seconds = try? container.decode(Double.self) {
            self.seconds = seconds
            self.local = nil
        } else {
            self.seconds = nil
            self.local = try container.decode(String.self)
        }
    }

    /// The absolute date, using the place's UTC offset for local strings.
    func date(utcOffset: Int) -> Date? {
        if let seconds { return Date(timeIntervalSince1970: seconds) }
        guard let local else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: utcOffset)
        formatter.dateFormat = local.contains("T") ? "yyyy-MM-dd'T'HH:mm" : "yyyy-MM-dd"
        return formatter.date(from: local)
    }
}

/// Field names are spelled out: `convertFromSnakeCase` turns "temperature_2m" into "temperature2M",
/// which silently fails to match, so it isn't used.
struct ForecastResponse: Decodable {
    let utcOffsetSeconds: Int
    let timezone: String?
    let current: Current
    let hourly: Hourly
    let daily: Daily

    enum CodingKeys: String, CodingKey {
        case utcOffsetSeconds = "utc_offset_seconds"
        case timezone, current, hourly, daily
    }

    struct Current: Decodable {
        let time: APITime
        let temperature2m: Double
        let relativeHumidity2m: Double?
        let apparentTemperature: Double?
        let isDay: Int?
        let precipitation: Double?
        let weatherCode: Int?
        let windSpeed10m: Double?
        let windDirection10m: Double?
        let pressureMsl: Double?

        enum CodingKeys: String, CodingKey {
            case time
            case temperature2m = "temperature_2m"
            case relativeHumidity2m = "relative_humidity_2m"
            case apparentTemperature = "apparent_temperature"
            case isDay = "is_day"
            case precipitation
            case weatherCode = "weather_code"
            case windSpeed10m = "wind_speed_10m"
            case windDirection10m = "wind_direction_10m"
            case pressureMsl = "pressure_msl"
        }
    }

    struct Hourly: Decodable {
        let time: [APITime]
        let temperature2m: [Double?]
        let precipitationProbability: [Double?]?
        let weatherCode: [Int?]
        let isDay: [Int?]?

        enum CodingKeys: String, CodingKey {
            case time
            case temperature2m = "temperature_2m"
            case precipitationProbability = "precipitation_probability"
            case weatherCode = "weather_code"
            case isDay = "is_day"
        }
    }

    struct Daily: Decodable {
        let time: [APITime]
        let weatherCode: [Int?]
        let temperature2mMax: [Double?]
        let temperature2mMin: [Double?]
        let precipitationProbabilityMax: [Double?]?
        let sunrise: [APITime?]?
        let sunset: [APITime?]?
        let uvIndexMax: [Double?]?

        enum CodingKeys: String, CodingKey {
            case time
            case weatherCode = "weather_code"
            case temperature2mMax = "temperature_2m_max"
            case temperature2mMin = "temperature_2m_min"
            case precipitationProbabilityMax = "precipitation_probability_max"
            case sunrise, sunset
            case uvIndexMax = "uv_index_max"
        }
    }
}

struct GeocodingResponse: Decodable {
    /// Missing entirely when nothing matches.
    let results: [Result]?

    struct Result: Decodable {
        let id: Int
        let name: String
        let latitude: Double
        let longitude: Double
        let country: String?
        let admin1: String?
    }
}
