import Foundation
import Observation
import WeatherCore

/// City search with a short pause after typing, so each keystroke doesn't hit the network.
@MainActor
@Observable
public final class PlaceSearchModel {
    public var query = ""
    public private(set) var results: [Place] = []
    public private(set) var isSearching = false
    public private(set) var errorMessage: String?

    @ObservationIgnored private let service: PlaceSearchService
    @ObservationIgnored private let pause: @Sendable () async throws -> Void

    public init(
        service: PlaceSearchService,
        pause: @escaping @Sendable () async throws -> Void = { try await Task.sleep(for: .milliseconds(300)) }
    ) {
        self.service = service
        self.pause = pause
    }

    public var isActive: Bool {
        !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Call from `.task(id: query)`: typing again cancels the previous search during its pause.
    public func search() async {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            results = []
            errorMessage = nil
            return
        }
        do {
            try await pause()
        } catch {
            return   // cancelled by the next keystroke
        }
        isSearching = true
        defer { isSearching = false }
        do {
            let found = try await service.searchPlaces(matching: text)
            guard !Task.isCancelled else { return }
            results = found
            errorMessage = found.isEmpty ? "No results for “\(text)”" : nil
        } catch let error as WeatherError {
            results = []
            errorMessage = error.message
        } catch {
            results = []
            errorMessage = WeatherError.unavailable.message
        }
    }

    public func clear() {
        query = ""
        results = []
        errorMessage = nil
    }
}
