//
//  UserLocationService.swift
//  EventPassUG
//
//  User location tracking service for proximity-based recommendations
//  Privacy-first approach: approximate location only, no precise tracking
//

import Foundation
import CoreLocation
import Combine

@MainActor
class UserLocationService: NSObject, ObservableObject {

    // MARK: - Singleton

    static let shared = UserLocationService()

    // MARK: - Published Properties

    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var currentLocation: UserLocation?
    @Published var isUpdatingLocation = false
    @Published var locationError: LocationError?

    // MARK: - Private Properties

    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()

    // MARK: - Initialization

    private override init() {
        super.init()
        setupLocationManager()
    }

    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer // Approximate, not precise
        locationManager.distanceFilter = 1000 // Update only if moved 1km
        authorizationStatus = locationManager.authorizationStatus
    }

    // MARK: - Permission Handling

    /// Request location permission with clear explanation
    func requestPermission() {
        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            locationError = .permissionDenied
        case .authorizedWhenInUse, .authorizedAlways:
            startUpdatingLocation()
        @unknown default:
            locationError = .unknown
        }
    }

    /// Check if location services are available
    var isLocationAvailable: Bool {
        CLLocationManager.locationServicesEnabled()
    }

    /// Check if user has granted permission
    var hasPermission: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }

    // MARK: - Location Updates

    /// Start updating user location
    func startUpdatingLocation() {
        guard isLocationAvailable else {
            locationError = .servicesDisabled
            return
        }

        guard hasPermission else {
            locationError = .permissionDenied
            return
        }

        isUpdatingLocation = true
        locationManager.requestLocation()
    }

    /// Stop updating location
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
        isUpdatingLocation = false
    }

    /// Update location manually with city/country
    func updateLocation(city: String, country: String, coordinate: UserLocation.LocationCoordinate) {
        currentLocation = UserLocation(
            city: city,
            country: country,
            coordinate: coordinate,
            lastUpdated: Date()
        )
    }

    // MARK: - Distance Calculation

    /// Calculate distance between user and event venue in kilometers
    func distance(to venue: Venue) -> Double? {
        guard let userLocation = currentLocation else { return nil }

        let userCLLocation = CLLocation(
            latitude: userLocation.coordinate.latitude,
            longitude: userLocation.coordinate.longitude
        )

        let venueCLLocation = CLLocation(
            latitude: venue.coordinate.latitude,
            longitude: venue.coordinate.longitude
        )

        return userCLLocation.distance(from: venueCLLocation) / 1000 // Convert to km
    }

    /// Check if event is within specified radius (in kilometers)
    func isWithinRadius(event: Event, radiusKm: Double) -> Bool {
        guard let distance = distance(to: event.venue) else { return false }
        return distance <= radiusKm
    }

    // MARK: - Geocoding

    /// Reverse geocode coordinates to get city and country
    private func reverseGeocode(location: CLLocation) async throws -> (city: String, country: String) {
        return try await withCheckedThrowingContinuation { continuation in
            geocoder.reverseGeocodeLocation(location) { placemarks, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let placemark = placemarks?.first else {
                    continuation.resume(throwing: LocationError.geocodingFailed)
                    return
                }

                let city = placemark.locality ?? placemark.subAdministrativeArea ?? "Unknown"
                let country = placemark.country ?? "Unknown"

                continuation.resume(returning: (city, country))
            }
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension UserLocationService: CLLocationManagerDelegate {

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationStatus = manager.authorizationStatus

            if hasPermission {
                startUpdatingLocation()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        Task { @MainActor in
            do {
                let (city, country) = try await reverseGeocode(location: location)

                currentLocation = UserLocation(
                    city: city,
                    country: country,
                    coordinate: UserLocation.LocationCoordinate(clCoordinate: location.coordinate),
                    lastUpdated: Date()
                )

                isUpdatingLocation = false
                locationError = nil
            } catch {
                locationError = .geocodingFailed
                isUpdatingLocation = false
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            if let clError = error as? CLError {
                switch clError.code {
                case .denied:
                    locationError = .permissionDenied
                case .network:
                    locationError = .networkError
                default:
                    locationError = .unknown
                }
            } else {
                locationError = .unknown
            }

            isUpdatingLocation = false
        }
    }
}

// MARK: - Location Error

enum LocationError: LocalizedError {
    case servicesDisabled
    case permissionDenied
    case geocodingFailed
    case networkError
    case unknown

    var errorDescription: String? {
        switch self {
        case .servicesDisabled:
            return "Location services are disabled. Please enable them in Settings."
        case .permissionDenied:
            return "Location permission denied. Please grant permission in Settings to see nearby events."
        case .geocodingFailed:
            return "Unable to determine your location. Please try again."
        case .networkError:
            return "Network error while fetching location. Please check your connection."
        case .unknown:
            return "An unknown error occurred while getting your location."
        }
    }

    var recoverySuggestion: String {
        switch self {
        case .servicesDisabled, .permissionDenied:
            return "You can still browse all events or manually set your location."
        case .geocodingFailed, .networkError, .unknown:
            return "Try again or manually enter your city."
        }
    }
}
