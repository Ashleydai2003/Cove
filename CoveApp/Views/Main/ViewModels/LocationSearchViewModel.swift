//
//  LocationSearchViewModel.swift
//  Cove
//
//  Cove
//  Created by Nesib Muhedin

import Foundation
import MapKit
import Combine
import Contacts

class LocationSearchViewModel: NSObject, ObservableObject {

    @Published var searchQuery = ""
    @Published var searchResults: [MKLocalSearchCompletion] = []

    private var completer = MKLocalSearchCompleter()
    private var cancellables = Set<AnyCancellable>()

    override init() {
        super.init()
        completer.resultTypes = .address

        $searchQuery
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] query in
                self?.completer.queryFragment = query
            }
            .store(in: &cancellables)

        completer.resultTypes = .address
        completer.delegate = self
    }

    func selectLocation(completion: MKLocalSearchCompletion, onResult: @escaping (String?) -> Void) {
        let request = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            if let placemark = response?.mapItems.first?.placemark {
                Log.debug("Full address: \(self.formattedAddress(from: placemark))")
                let location = self.formattedAddress(from: placemark)
                onResult(location)
            } else {
                onResult(nil)
            }
        }
    }

    func formattedAddress(from placemark: CLPlacemark) -> String {
        // Concise address: "123 Main St, City, State"
        var parts: [String] = []

        let streetNumber = placemark.subThoroughfare
        let streetName = placemark.thoroughfare
        let city = placemark.locality
        let state = placemark.administrativeArea

        if let streetName {
            let street = [streetNumber, streetName].compactMap { $0 }.joined(separator: " ")
            if !street.isEmpty { parts.append(street) }
        } else if let name = placemark.name { // fallback to name if no street
            parts.append(name)
        }

        if let city, !city.isEmpty { parts.append(city) }
        if let state, !state.isEmpty { parts.append(state) }

        if parts.isEmpty {
            return [placemark.country].compactMap { $0 }.joined()
        }
        return parts.joined(separator: ", ")
    }
}

extension LocationSearchViewModel: MKLocalSearchCompleterDelegate {

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        DispatchQueue.main.async {
            self.searchResults = completer.results
        }
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        Log.error("Search completer error: \(error.localizedDescription)")
    }
}
