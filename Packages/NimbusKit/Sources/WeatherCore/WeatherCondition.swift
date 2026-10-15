import Foundation

/// What the sky is doing, decoded from a WMO weather code (the standard Open-Meteo uses).
public enum WeatherCondition: String, CaseIterable, Sendable {
    case clear
    case mainlyClear
    case partlyCloudy
    case overcast
    case fog
    case drizzle
    case freezingDrizzle
    case rain
    case freezingRain
    case snow
    case rainShowers
    case snowShowers
    case thunderstorm
    case unknown

    /// The broad kind of weather, which picks the background.
    public enum Sky: String, Sendable {
        case clear
        case cloudy
        case fog
        case rain
        case snow
        case storm
    }

    /// https://open-meteo.com/en/docs (WMO Weather interpretation codes)
    public init(wmoCode: Int) {
        switch wmoCode {
        case 0: self = .clear
        case 1: self = .mainlyClear
        case 2: self = .partlyCloudy
        case 3: self = .overcast
        case 45, 48: self = .fog
        case 51, 53, 55: self = .drizzle
        case 56, 57: self = .freezingDrizzle
        case 61, 63, 65: self = .rain
        case 66, 67: self = .freezingRain
        case 71, 73, 75, 77: self = .snow
        case 80, 81, 82: self = .rainShowers
        case 85, 86: self = .snowShowers
        case 95...99: self = .thunderstorm
        default: self = .unknown
        }
    }

    public var title: String {
        switch self {
        case .clear: "Clear"
        case .mainlyClear: "Mostly Clear"
        case .partlyCloudy: "Partly Cloudy"
        case .overcast: "Cloudy"
        case .fog: "Fog"
        case .drizzle: "Drizzle"
        case .freezingDrizzle: "Freezing Drizzle"
        case .rain: "Rain"
        case .freezingRain: "Freezing Rain"
        case .snow: "Snow"
        case .rainShowers: "Showers"
        case .snowShowers: "Snow Showers"
        case .thunderstorm: "Thunderstorms"
        case .unknown: "—"
        }
    }

    public var sky: Sky {
        switch self {
        case .clear, .mainlyClear, .unknown: .clear
        case .partlyCloudy, .overcast: .cloudy
        case .fog: .fog
        case .drizzle, .freezingDrizzle, .rain, .freezingRain, .rainShowers: .rain
        case .snow, .snowShowers: .snow
        case .thunderstorm: .storm
        }
    }

    /// An SF Symbol, with a moon instead of a sun at night.
    public func symbolName(isDay: Bool = true) -> String {
        switch self {
        case .clear: isDay ? "sun.max.fill" : "moon.stars.fill"
        case .mainlyClear, .partlyCloudy: isDay ? "cloud.sun.fill" : "cloud.moon.fill"
        case .overcast: "cloud.fill"
        case .fog: "cloud.fog.fill"
        case .drizzle, .freezingDrizzle: "cloud.drizzle.fill"
        case .rain, .freezingRain: "cloud.rain.fill"
        case .rainShowers: isDay ? "cloud.sun.rain.fill" : "cloud.moon.rain.fill"
        case .snow, .snowShowers: "cloud.snow.fill"
        case .thunderstorm: "cloud.bolt.rain.fill"
        case .unknown: "questionmark"
        }
    }
}
