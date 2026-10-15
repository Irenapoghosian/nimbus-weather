import Foundation
import WeatherCore

/// Turns Open-Meteo's column-shaped JSON into rows of forecasts.
enum ForecastMapper {

    struct MissingData: Error {}

    static func forecast(from response: ForecastResponse, for place: Place) throws -> Forecast {
        let offset = response.utcOffsetSeconds
        let timeZone = response.timezone.flatMap(TimeZone.init(identifier:))
            ?? TimeZone(secondsFromGMT: offset)
            ?? .gmt
        guard let currentTime = response.current.time.date(utcOffset: offset) else { throw MissingData() }

        return Forecast(
            place: place,
            timeZone: timeZone,
            current: current(from: response.current, at: currentTime),
            hourly: hourly(from: response.hourly, utcOffset: offset),
            daily: daily(from: response.daily, utcOffset: offset)
        )
    }

    static func place(from result: GeocodingResponse.Result) -> Place {
        Place(
            id: String(result.id),
            name: result.name,
            region: result.admin1,
            country: result.country,
            latitude: result.latitude,
            longitude: result.longitude
        )
    }

    private static func current(from current: ForecastCurrent, at time: Date) -> CurrentConditions {
        CurrentConditions(
            time: time,
            temperature: current.temperature2m,
            apparentTemperature: current.apparentTemperature ?? current.temperature2m,
            humidity: Int((current.relativeHumidity2m ?? 0).rounded()),
            precipitation: current.precipitation ?? 0,
            windSpeed: current.windSpeed10m ?? 0,
            windDirection: Int((current.windDirection10m ?? 0).rounded()),
            pressure: current.pressureMsl ?? 0,
            condition: WeatherCondition(wmoCode: current.weatherCode ?? -1),
            isDay: (current.isDay ?? 1) == 1
        )
    }

    /// Hours with a missing time or temperature are skipped rather than shown as zero.
    private static func hourly(from hourly: ForecastHourly, utcOffset: Int) -> [HourlyForecast] {
        hourly.time.indices.compactMap { index in
            guard
                let time = hourly.time[index].date(utcOffset: utcOffset),
                let temperature = hourly.temperature2m.value(at: index)
            else { return nil }
            let chance = hourly.precipitationProbability?.value(at: index)
            let code = hourly.weatherCode.value(at: index)
            let isDay = hourly.isDay?.value(at: index)
            return HourlyForecast(
                time: time,
                temperature: temperature,
                precipitationChance: chance.map { Int($0.rounded()) },
                condition: WeatherCondition(wmoCode: code ?? -1),
                isDay: (isDay ?? 1) == 1
            )
        }
    }

    private static func daily(from daily: ForecastDaily, utcOffset: Int) -> [DailyForecast] {
        daily.time.indices.compactMap { index in
            guard
                let date = daily.time[index].date(utcOffset: utcOffset),
                let high = daily.temperature2mMax.value(at: index),
                let low = daily.temperature2mMin.value(at: index)
            else { return nil }
            let chance = daily.precipitationProbabilityMax?.value(at: index)
            let code = daily.weatherCode.value(at: index)
            let sunrise = daily.sunrise?.value(at: index)
            let sunset = daily.sunset?.value(at: index)
            return DailyForecast(
                date: date,
                high: high,
                low: low,
                precipitationChance: chance.map { Int($0.rounded()) },
                condition: WeatherCondition(wmoCode: code ?? -1),
                sunrise: sunrise?.date(utcOffset: utcOffset),
                sunset: sunset?.date(utcOffset: utcOffset),
                uvIndexMax: daily.uvIndexMax?.value(at: index)
            )
        }
    }
}

extension Array {
    /// A column's value, or `nil` when it's missing or the column is shorter than the times
    /// (Open-Meteo can return columns of different lengths).
    func value<Wrapped>(at index: Int) -> Wrapped? where Element == Wrapped? {
        indices.contains(index) ? self[index] : nil
    }
}
