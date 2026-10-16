import SwiftUI
import UIKit
import WeatherCore

/// One page: loading, an error with a way out, or the full forecast.
struct WeatherPageView: View {
    let model: WeatherViewModel
    /// Opens the city list, offered when the location can't be used.
    let searchCity: () -> Void

    var body: some View {
        content
            .task { await model.loadIfNeeded() }
    }

    @ViewBuilder
    private var content: some View {
        switch model.state {
        case .loading:
            VStack(spacing: 16) {
                Text(model.title).font(.largeTitle)
                ProgressView().controlSize(.large).tint(.white)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .failed(let error):
            ErrorStateView(title: model.title, error: error, searchCity: searchCity) {
                Task { await model.load() }
            }
        case .loaded(let forecast):
            ForecastScrollView(model: model, forecast: forecast)
        }
    }
}

/// The loaded forecast, top to bottom, with pull to refresh.
struct ForecastScrollView: View {
    let model: WeatherViewModel
    let forecast: Forecast

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                CurrentHeader(title: model.title, isCurrentLocation: model.isCurrentLocation, forecast: forecast)
                HourlyCard(hours: model.upcomingHours, timeZone: forecast.timeZone)
                HourlyChartView(hours: model.upcomingHours, timeZone: forecast.timeZone)
                DailyCard(days: forecast.daily, timeZone: forecast.timeZone, now: model.currentTime)
                DetailsGrid(items: ForecastDetails.items(for: forecast))
                AttributionFooter(lastUpdated: model.lastUpdated)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .refreshable { await model.refresh() }
    }
}

/// What went wrong, and the one button that helps.
struct ErrorStateView: View {
    let title: String
    let error: WeatherError
    let searchCity: () -> Void
    let retry: () -> Void
    @Environment(\.openURL) private var openURL

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: symbolName)
        } description: {
            Text(error.message)
        } actions: {
            if error == .locationDenied {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button("Try Again", action: retry)
                    .buttonStyle(.borderedProminent)
            }
            if isLocationError {
                Button("Search for a City", action: searchCity)
                    .buttonStyle(.bordered)
            }
        }
        .foregroundStyle(.white)
    }

    private var isLocationError: Bool {
        error == .locationDenied || error == .locationUnavailable
    }

    private var symbolName: String {
        switch error {
        case .offline: "wifi.slash"
        case .unavailable: "exclamationmark.icloud"
        case .locationDenied, .locationUnavailable: "location.slash"
        }
    }
}
