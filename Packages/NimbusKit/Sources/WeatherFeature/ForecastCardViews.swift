import DesignSystem
import SwiftUI
import WeatherCore

/// City, big temperature, condition and today's high and low.
struct CurrentHeader: View {
    let title: String
    let isCurrentLocation: Bool
    let forecast: Forecast

    var body: some View {
        VStack(spacing: 2) {
            if isCurrentLocation {
                Label("My Location", systemImage: "location.fill")
                    .font(.caption.weight(.semibold))
                    .textCase(.uppercase)
                    .opacity(0.8)
            }
            Text(title)
                .font(.largeTitle)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(NimbusFormat.temperature(forecast.current.temperature))
                .font(.system(size: 96, weight: .thin))
            Text(forecast.current.condition.title)
                .font(.title3.weight(.medium))
            if let today = forecast.today {
                Text(NimbusFormat.highLow(high: today.high, low: today.low))
                    .font(.title3.weight(.medium))
            }
        }
        .foregroundStyle(.white)
        .shadow(color: .black.opacity(0.2), radius: 6, y: 2)
        .padding(.top, 36)
        .padding(.bottom, 12)
        .accessibilityElement(children: .combine)
    }
}

/// The next 24 hours in a horizontal strip.
struct HourlyCard: View {
    let hours: [HourlyForecast]
    let timeZone: TimeZone

    var body: some View {
        GlassCard("Hourly forecast", systemImage: "clock") {
            ScrollView(.horizontal) {
                HStack(spacing: 20) {
                    ForEach(Array(hours.enumerated()), id: \.element.id) { index, hour in
                        HourColumn(label: index == 0 ? "Now" : NimbusFormat.hour(hour.time, in: timeZone), hour: hour)
                    }
                }
                .padding(.vertical, 4)
            }
            .scrollIndicators(.hidden)
        }
    }
}

struct HourColumn: View {
    let label: String
    let hour: HourlyForecast

    var body: some View {
        VStack(spacing: 8) {
            Text(label).font(.subheadline.weight(.semibold))
            VStack(spacing: 2) {
                ConditionIcon(hour.condition, isDay: hour.isDay).font(.title3)
                if let chance = ForecastRules.notablePrecipitationChance(hour.precipitationChance) {
                    Text(NimbusFormat.percent(chance)).font(.caption2.weight(.bold)).foregroundStyle(.cyan)
                }
            }
            .frame(height: 44)
            Text(NimbusFormat.temperature(hour.temperature)).font(.headline)
        }
        .foregroundStyle(.white)
        .accessibilityElement(children: .combine)
    }
}

/// Ten days, with each day's range drawn on the week's shared scale.
struct DailyCard: View {
    let days: [DailyForecast]
    let timeZone: TimeZone
    let now: Date

    var body: some View {
        GlassCard("10-day forecast", systemImage: "calendar") {
            let span = ForecastRules.temperatureSpan(of: days) ?? 0...1
            VStack(spacing: 0) {
                ForEach(Array(days.enumerated()), id: \.element.id) { index, day in
                    if index > 0 {
                        Divider().overlay(.white.opacity(0.2))
                    }
                    DayRow(
                        weekday: NimbusFormat.weekday(day.date, in: timeZone, now: now),
                        day: day,
                        position: ForecastRules.barPosition(for: day, in: span)
                    )
                }
            }
        }
    }
}

struct DayRow: View {
    let weekday: String
    let day: DailyForecast
    let position: ClosedRange<Double>

    var body: some View {
        HStack(spacing: 12) {
            Text(weekday).frame(width: 56, alignment: .leading)
            VStack(spacing: 0) {
                ConditionIcon(day.condition)
                if let chance = ForecastRules.notablePrecipitationChance(day.precipitationChance) {
                    Text(NimbusFormat.percent(chance)).font(.caption2.weight(.bold)).foregroundStyle(.cyan)
                }
            }
            .frame(width: 36)
            Text(NimbusFormat.temperature(day.low))
                .foregroundStyle(.white.opacity(0.6))
                .frame(width: 40, alignment: .trailing)
            TemperatureRangeBar(position: position)
            Text(NimbusFormat.temperature(day.high))
                .frame(width: 40, alignment: .trailing)
        }
        .font(.headline)
        .foregroundStyle(.white)
        .padding(.vertical, 10)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(weekday), \(day.condition.title), low \(NimbusFormat.temperature(day.low)), high \(NimbusFormat.temperature(day.high))"
        )
    }
}

/// Feels like, humidity, wind, pressure, UV and sunrise in a two-column grid.
struct DetailsGrid: View {
    let items: [DetailItem]

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
            ForEach(items) { item in
                GlassCard(item.title, systemImage: item.systemImage) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(item.value)
                            .font(.title2.weight(.medium))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Spacer(minLength: 0)
                        if let footnote = item.footnote {
                            Text(footnote).font(.footnote).foregroundStyle(.white.opacity(0.8))
                        }
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 84, alignment: .topLeading)
                }
                .accessibilityElement(children: .combine)
            }
        }
    }
}

/// Open-Meteo's data is CC BY 4.0, so the app credits it under every forecast.
struct AttributionFooter: View {
    let lastUpdated: Date?

    private static let openMeteo = URL(string: "https://open-meteo.com/")

    var body: some View {
        VStack(spacing: 4) {
            if let lastUpdated {
                Text("Updated \(NimbusFormat.time(lastUpdated, in: .current))")
            }
            if let url = Self.openMeteo {
                Link("Weather data by Open-Meteo.com", destination: url)
                    .underline()
            }
        }
        .font(.footnote)
        .foregroundStyle(.white.opacity(0.75))
        .padding(.top, 8)
    }
}
