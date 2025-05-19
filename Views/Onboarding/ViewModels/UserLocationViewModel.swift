//
//  UserLocationViewModel.swift
//  Cove
//

import Foundation
import MapKit

final class UserLocationViewModel: BaseViewModel {
    
    @Published var locationManager = LocationManager()
    /// State variables for coordinate
    @Published var selectedCoordinate: CLLocationCoordinate2D?
    @Published var placemark: CLPlacemark?
    
    /// State variables for location components
    @Published var state = ""
    @Published var city = ""
    @Published var zipcode = ""
    
    /// Start updating user's current location
    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }
    
    /// Stop updating user's current location
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    /// Reverse geocode location and get placemark
    /// Fetch zipcode, state & city from the tapped location
    func getPlacemark(from coordinate: CLLocationCoordinate2D) {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
            if let placemark = placemarks?.first {
                self.placemark = placemark
                
                if let state = placemark.administrativeArea {
                    self.state = state
                }
                if let locality = placemark.locality {
                    self.city = locality
                }
                if let postalCode = placemark.postalCode {
                    self.zipcode = postalCode
                }
                
            } else {
                print("Error getting placemark:", error?.localizedDescription ?? "Unknown error")
            }
        }
    }
    
    func searchZip(_ zip: String) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(zip) { placemarks, error in
            if let coordinate = placemarks?.first?.location?.coordinate {
                self.selectedCoordinate = coordinate
            } else {
                print("ZIP not found:", error?.localizedDescription ?? "Unknown error")
            }
        }
    }
}
