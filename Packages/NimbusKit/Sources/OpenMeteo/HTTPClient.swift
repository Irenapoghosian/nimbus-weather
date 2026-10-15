import Foundation

/// The one thing the client needs from the network, so tests can answer with fixtures.
public protocol HTTPClient: Sendable {
    func data(from url: URL) async throws -> (Data, HTTPURLResponse)
}
