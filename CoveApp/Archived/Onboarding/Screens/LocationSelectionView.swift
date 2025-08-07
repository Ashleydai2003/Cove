//
//  LocationSelectionView.swift
//  Cove
//
//  Archived from ProfileView.swift
//  NOTE: This archived code has dependencies on MapView, Colors, and Log
//  that would need to be imported/included if restoring this functionality

import SwiftUI
import CoreLocation
import MapKit

// MARK: - Location Selection View (ARCHIVED)
// Dependencies needed: MapView, Colors, Log
struct LocationSelectionView: View {
    let currentAddress: String
    let onLocationSelected: (String, CLLocationCoordinate2D) -> Void
    @State private var userLocation: CLLocation?
    @State private var coordinate: CLLocationCoordinate2D?
    @State private var selectedAddress: String = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                MapView(userLocation: $userLocation, coordinate: $coordinate)
                    .onChange(of: coordinate) { _, newCoordinate in
                        if let coord = newCoordinate {
                            Task {
                                selectedAddress = await getLocationName(latitude: coord.latitude, longitude: coord.longitude)
                            }
                        }
                    }

                VStack(spacing: 16) {
                    Text("selected location")
                        .font(.LibreBodoni(size: 18))
                        .foregroundColor(Colors.primaryDark)

                    Text(selectedAddress.isEmpty ? "Tap on the map to select a location" : selectedAddress.lowercased())
                        .font(.LeagueSpartan(size: 14))
                        .foregroundColor(Colors.k6F6F73)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Button(action: {
                        if let coord = coordinate, !selectedAddress.isEmpty {
                            onLocationSelected(selectedAddress, coord)
                            dismiss()
                        }
                    }) {
                        Text("confirm location")
                            .font(.LibreBodoni(size: 16))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Colors.primaryDark)
                            )
                    }
                    .disabled(selectedAddress.isEmpty)
                    .opacity(selectedAddress.isEmpty ? 0.5 : 1.0)
                }
                .padding()
            }
            .navigationTitle("Select Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func getLocationName(latitude: Double, longitude: Double) async -> String {
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
            Log.debug("Geocoding error: \(error.localizedDescription)")
        }
        return ""
    }
} 