import CoreLocation
import WeatherCore

/// The device's location as a named place, asking for "When In Use" permission the first time.
///
/// Core Location reports through a delegate; this wraps one request in `async`.
@MainActor
public final class DeviceLocationProvider: NSObject, LocationProvider {
    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var authorization: CheckedContinuation<CLAuthorizationStatus, Never>?
    private var location: CheckedContinuation<CLLocation, Error>?

    override public init() {
        super.init()
        manager.delegate = self
        // City-level accuracy is plenty for weather and comes back much faster.
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    public nonisolated func currentPlace() async throws -> Place {
        try await resolvePlace()
    }

    private func resolvePlace() async throws -> Place {
        let status = await authorizationStatus()
        guard status == .authorizedWhenInUse || status == .authorizedAlways else {
            throw WeatherError.locationDenied
        }
        let found = try await requestLocation()
        let placemark = try? await geocoder.reverseGeocodeLocation(found).first
        return LocationNaming.place(
            latitude: found.coordinate.latitude,
            longitude: found.coordinate.longitude,
            locality: placemark?.locality,
            region: placemark?.administrativeArea,
            country: placemark?.country
        )
    }

    private func authorizationStatus() async -> CLAuthorizationStatus {
        let status = manager.authorizationStatus
        guard status == .notDetermined else { return status }
        return await withCheckedContinuation { continuation in
            authorization = continuation
            manager.requestWhenInUseAuthorization()
        }
    }

    private func requestLocation() async throws -> CLLocation {
        try await withCheckedThrowingContinuation { continuation in
            location?.resume(throwing: WeatherError.locationUnavailable)
            location = continuation
            manager.requestLocation()
        }
    }
}

extension DeviceLocationProvider: CLLocationManagerDelegate {
    public nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            guard status != .notDetermined else { return }
            authorization?.resume(returning: status)
            authorization = nil
        }
    }

    public nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let last = locations.last else { return }
        Task { @MainActor in
            location?.resume(returning: last)
            location = nil
        }
    }

    public nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            location?.resume(throwing: WeatherError.locationUnavailable)
            location = nil
        }
    }
}
