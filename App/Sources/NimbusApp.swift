import SwiftUI
import WeatherFeature

@main
struct NimbusApp: App {
    /// Built once at launch; owns the services and the list of cities.
    @State private var container = AppContainer.live()

    var body: some Scene {
        WindowGroup {
            NimbusRootView(model: container.model)
        }
    }
}
