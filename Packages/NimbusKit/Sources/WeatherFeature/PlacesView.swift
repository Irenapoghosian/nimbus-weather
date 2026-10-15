import DesignSystem
import SwiftUI
import WeatherCore

/// The city list: search to add a city, swipe to delete, drag to reorder.
struct PlacesView: View {
    @Bindable var model: NimbusModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        @Bindable var search = model.search
        NavigationStack {
            List {
                if search.isActive {
                    searchResults
                } else {
                    savedPlaces
                }
            }
            .navigationTitle("Weather")
            .searchable(text: $search.query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search for a city")
            .autocorrectionDisabled()
            .task(id: search.query) { await search.search() }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
                if !search.isActive && !model.savedPlaces.isEmpty {
                    ToolbarItem(placement: .topBarLeading) { EditButton() }
                }
            }
        }
    }

    private var searchResults: some View {
        Section {
            if model.search.isSearching && model.search.results.isEmpty {
                ProgressView().frame(maxWidth: .infinity)
            }
            ForEach(model.search.results) { place in
                Button {
                    model.add(place)
                    dismiss()
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(place.name).font(.headline)
                        if !place.subtitle.isEmpty {
                            Text(place.subtitle).font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                }
                .tint(.primary)
            }
            if let message = model.search.errorMessage {
                Text(message).foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var savedPlaces: some View {
        Section {
            ForEach(model.pages.filter { $0.isCurrentLocation }) { page in
                row(for: page)
            }
        }
        Section {
            ForEach(model.pages.filter { !$0.isCurrentLocation }) { page in
                row(for: page)
            }
            .onDelete { model.removeSavedPlaces(atOffsets: $0) }
            .onMove { model.movePlaces(fromOffsets: $0, toOffset: $1) }
        } header: {
            Text("Saved")
        } footer: {
            if model.savedPlaces.isEmpty {
                Text("Search for a city to add it here.")
            }
        }
    }

    private func row(for page: WeatherViewModel) -> some View {
        Button {
            model.selectedID = page.id
            dismiss()
        } label: {
            PlaceRow(page: page)
        }
        .tint(.primary)
    }
}

/// A city with its current temperature, loaded when the row appears.
struct PlaceRow: View {
    let page: WeatherViewModel

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    if page.isCurrentLocation {
                        Image(systemName: "location.fill").font(.caption)
                    }
                    Text(page.title).font(.headline)
                }
                if !page.subtitle.isEmpty {
                    Text(page.subtitle).font(.subheadline).foregroundStyle(.secondary)
                }
            }
            Spacer()
            if let forecast = page.forecast {
                ConditionIcon(forecast.current.condition, isDay: forecast.current.isDay).font(.title3)
                Text(NimbusFormat.temperature(forecast.current.temperature))
                    .font(.title2.weight(.medium))
                    .monospacedDigit()
            } else if page.state == .loading {
                ProgressView()
            }
        }
        .padding(.vertical, 4)
        .task { await page.loadIfNeeded() }
    }
}
