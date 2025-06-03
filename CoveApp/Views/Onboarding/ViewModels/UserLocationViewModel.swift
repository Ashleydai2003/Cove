//
//  UserLocationViewModel.swift
//  Cove
//  Created by Ananya Agarwal

import Foundation
import MapKit

final class UserLocationViewModel: BaseViewModel {
    
    @Published var locationManager = LocationManager()
    @Published var selectedCoordinate: CLLocationCoordinate2D?
    @Published var placemark: CLPlacemark?
    
    @Published var state = ""
    @Published var city = ""
    @Published var zipcode = ""
    
    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    func getPlacemark(from coordinate: CLLocationCoordinate2D) {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
            if let placemark = placemarks?.first {
                self.placemark = placemark
                print("State: \(placemark)")
                
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
    
}
