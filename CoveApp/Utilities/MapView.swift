//
//  MapView.swift
//  Cove
//  Created by Ananya Agarwal

import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {

    @Binding var userLocation: CLLocation?
    @Binding var coordinate: CLLocationCoordinate2D?

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow

        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        mapView.addGestureRecognizer(tapGesture)
        mapView.delegate = context.coordinator

        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.removeAnnotations(uiView.annotations)

        if let location = userLocation {
            let region = MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
            uiView.setRegion(region, animated: true)
        } else {

            if let coord = coordinate {
                let annotation = MKPointAnnotation()
                annotation.coordinate = coord
                uiView.addAnnotation(annotation)

                let region = MKCoordinateRegion(center: coord, latitudinalMeters: 1000, longitudinalMeters: 1000)
                uiView.setRegion(region, animated: true)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView

        init(_ parent: MapView) {
            self.parent = parent
        }

        @objc func handleTap(_ gestureRecognizer: UITapGestureRecognizer) {
            guard let mapView = gestureRecognizer.view as? MKMapView else { return }
            let point = gestureRecognizer.location(in: mapView)
            let coord = mapView.convert(point, toCoordinateFrom: mapView)
            parent.coordinate = coord
        }
    }

}
