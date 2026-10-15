import Foundation

public struct CurrentConditions: Equatable, Sendable {
    public let time: Date
    /// °C
    public let temperature: Double
    /// °C
    public let apparentTemperature: Double
    /// 0…100
    public let humidity: Int
    /// mm in the last hour
    public let precipitation: Double
    /// km/h
    public let windSpeed: Double
    /// Degrees the wind comes from, 0 = north.
    public let windDirection: Int
    /// hPa at sea level
    public let pressure: Double
    public let condition: WeatherCondition
    public let isDay: Bool

    public init(
        time: Date,
        temperature: Double,
        apparentTemperature: Double,
        humidity: Int,
        precipitation: Double,
        windSpeed: Double,
        windDirection: Int,
        pressure: Double,
        condition: WeatherCondition,
        isDay: Bool
    ) {
        self.time = time
        self.temperature = temperature
        self.apparentTemperature = apparentTemperature
        self.humidity = humidity
        self.precipitation = precipitation
        self.windSpeed = windSpeed
        self.windDirection = windDirection
        self.pressure = pressure
        self.condition = condition
        self.isDay = isDay
    }
}

public struct HourlyForecast: Equatable, Identifiable, Sendable {
    public let time: Date
    public let temperature: Double
    /// 0…100, `nil` when the model has no estimate.
    public let precipitationChance: Int?
    public let condition: WeatherCondition
    public let isDay: Bool

    public init(time: Date, temperature: Double, precipitationChance: Int?, condition: WeatherCondition, isDay: Bool) {
        self.time = time
        self.temperature = temperature
        self.precipitationChance = precipitationChance
        self.condition = condition
        self.isDay = isDay
    }

    public var id: Date { time }
}

public struct DailyForecast: Equatable, Identifiable, Sendable {
    /// Midnight at the place, as an absolute date.
    public let date: Date
    public let high: Double
    public let low: Double
    public let precipitationChance: Int?
    public let condition: WeatherCondition
    public let sunrise: Date?
    public let sunset: Date?
    public let uvIndexMax: Double?

    public init(
        date: Date,
        high: Double,
        low: Double,
        precipitationChance: Int?,
        condition: WeatherCondition,
        sunrise: Date? = nil,
        sunset: Date? = nil,
        uvIndexMax: Double? = nil
    ) {
        self.date = date
        self.high = high
        self.low = low
        self.precipitationChance = precipitationChance
        self.condition = condition
        self.sunrise = sunrise
        self.sunset = sunset
        self.uvIndexMax = uvIndexMax
    }

    public var id: Date { date }
}

/// Everything shown for one place.
public struct Forecast: Equatable, Sendable {
    public let place: Place
    /// The place's own time zone, so "15:00" means 15:00 there.
    public let timeZone: TimeZone
    public let current: CurrentConditions
    public let hourly: [HourlyForecast]
    public let daily: [DailyForecast]

    public init(place: Place, timeZone: TimeZone, current: CurrentConditions, hourly: [HourlyForecast], daily: [DailyForecast]) {
        self.place = place
        self.timeZone = timeZone
        self.current = current
        self.hourly = hourly
        self.daily = daily
    }

    /// Today's high and low, if the daily forecast has today.
    public var today: DailyForecast? { daily.first }
}
