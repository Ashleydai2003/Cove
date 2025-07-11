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
                print("Full address: \(self.formattedAddress(from: placemark))")
                let location = self.formattedAddress(from: placemark)
                onResult(location)
            } else {
                onResult(nil)
            }
        }
    }
    
    func formattedAddress(from placemark: CLPlacemark) -> String {
        var addressParts: [String] = []

        // Only include name if it's not already part of the city
        if let name = placemark.name,
           let city = placemark.locality,
           !name.contains(city) {
            addressParts.append(name)
        }
        
        if let street = placemark.thoroughfare {
            addressParts.append(street)
        }
        
        if let city = placemark.locality {
            addressParts.append(city)
        }
        
        if let state = placemark.administrativeArea {
            addressParts.append(state)
        }
        
        if let postalCode = placemark.postalCode {
            addressParts.append(postalCode)
        }
        
        if let country = placemark.country {
            addressParts.append(country)
        }

        return addressParts.joined(separator: ", ")
    }
}

extension LocationSearchViewModel: MKLocalSearchCompleterDelegate {
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        DispatchQueue.main.async {
            self.searchResults = completer.results
        }
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Search completer error: \(error.localizedDescription)")
    }
}
