import DesignSystem
import SwiftUI
import WeatherCore

/// Swipe between My Location and saved cities, over a sky that matches the weather on screen.
public struct NimbusRootView: View {
    @Bindable private var model: NimbusModel
    @State private var showsPlaces = false
    @Environment(\.scenePhase) private var scenePhase

    public init(model: NimbusModel) {
        self.model = model
    }

    public var body: some View {
        ZStack {
            SkyBackground(condition: shownCondition?.condition ?? .clear, isDay: shownCondition?.isDay ?? true)
            TabView(selection: $model.selectedID) {
                ForEach(model.pages) { page in
                    WeatherPageView(model: page) { showsPlaces = true }
                        .tag(page.id)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .safeAreaInset(edge: .bottom, spacing: 0) { bottomBar }
        .sheet(isPresented: $showsPlaces) {
            PlacesView(model: model)
        }
        .preferredColorScheme(.dark)
        .onChange(of: scenePhase) { _, phase in
            // Back from the background (or from Settings after allowing location): bring the page up to date.
            guard phase == .active, let page = model.selectedPage else { return }
            Task { await page.loadIfNeeded() }
        }
    }

    private var shownCondition: CurrentConditions? {
        model.selectedPage?.forecast?.current
    }

    private var bottomBar: some View {
        HStack {
            Color.clear.frame(width: 44, height: 44)
            Spacer()
            PageDots(pages: model.pages, selectedID: model.selectedID)
            Spacer()
            Button {
                showsPlaces = true
            } label: {
                Image(systemName: "list.bullet")
                    .font(.title3.weight(.semibold))
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Cities")
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        // A light dark tint reads on every sky; a material turned muddy over bright blue.
        .background(.black.opacity(0.18), ignoresSafeAreaEdges: .bottom)
        .overlay(alignment: .top) {
            Rectangle().fill(.white.opacity(0.15)).frame(height: 0.5)
        }
    }
}

/// The dots under the pages; My Location is an arrow, like in Apple Weather.
struct PageDots: View {
    let pages: [WeatherViewModel]
    let selectedID: String

    var body: some View {
        HStack(spacing: 8) {
            ForEach(pages) { page in
                Group {
                    if page.isCurrentLocation {
                        Image(systemName: "location.fill").font(.system(size: 9, weight: .bold))
                    } else {
                        Circle().frame(width: 7, height: 7)
                    }
                }
                .opacity(page.id == selectedID ? 1 : 0.4)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        let position = (pages.firstIndex { $0.id == selectedID } ?? 0) + 1
        return "Page \(position) of \(pages.count)"
    }
}
