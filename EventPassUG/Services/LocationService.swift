//
//  LocationService.swift
//  EventPassUG
//
//  Location autocomplete service using MapKit
//

import Foundation
import MapKit

struct LocationPrediction: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let coordinate: CLLocationCoordinate2D
}

@MainActor
class LocationService: ObservableObject {
    @Published var predictions: [LocationPrediction] = []
    @Published var isSearching = false

    private let searchCompleter = MKLocalSearchCompleter()
    private var currentSearch: MKLocalSearch?

    init() {
        searchCompleter.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 0.3476, longitude: 32.5825), // Kampala
            span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
        )
    }

    func searchLocations(query: String) {
        guard !query.isEmpty else {
            predictions = []
            return
        }

        isSearching = true
        currentSearch?.cancel()

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = searchCompleter.region

        let search = MKLocalSearch(request: request)
        currentSearch = search

        search.start { [weak self] response, error in
            guard let self = self else { return }

            Task { @MainActor in
                self.isSearching = false

                if let response = response {
                    self.predictions = response.mapItems.map { item in
                        LocationPrediction(
                            title: item.name ?? "",
                            subtitle: item.placemark.title ?? "",
                            coordinate: item.placemark.coordinate
                        )
                    }
                }
            }
        }
    }

    func selectLocation(_ prediction: LocationPrediction) -> (name: String, address: String, city: String, coordinate: (lat: Double, lon: Double)) {
        let components = prediction.subtitle.components(separatedBy: ", ")
        let address = components.first ?? prediction.subtitle
        let city = components.count > 1 ? components[1] : "Kampala"

        return (
            name: prediction.title,
            address: address,
            city: city,
            coordinate: (lat: prediction.coordinate.latitude, lon: prediction.coordinate.longitude)
        )
    }
}
