import Foundation
import CoreLocation

enum LocationUtils {
    static func getLocationName(latitude: Double, longitude: Double) async -> String {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: latitude, longitude: longitude)

        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            if let placemark = placemarks.first {
                let city = placemark.locality ?? ""
                let state = placemark.administrativeArea ?? ""
                return "\(city), \(state)"
            }
        } catch {
            Log.error("Geocoding error: \(error.localizedDescription)")
        }
        return ""
    }
}
