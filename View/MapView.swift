//
//  MapView.swift
//  AgroDonkey
//
//  Created by Ringo Wathelet on 2020/06/23.
//

import Foundation
import SwiftUI
import MapKit
import CoreLocation
import UserNotifications
import Combine


struct MapView: UIViewRepresentable  {
    
    @EnvironmentObject var land: LandModel

    let mapView = MKMapView()
 
    let locationManager = CLLocationManager()

    func makeUIView(context: Context) -> MKMapView {
        mapView.mapType = land.mapType
        mapView.showsUserLocation = true
        mapView.showsCompass = true
        mapView.delegate = context.coordinator
        mapView.setRegion(land.region, animated: true)
  
        setupLocationManager()

        return mapView
    }

    func setupLocationManager() {
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestAlwaysAuthorization()
        let status = locationManager.authorizationStatus
        #if !targetEnvironment(macCatalyst)
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            if CLLocationManager.locationServicesEnabled() {
                locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
                locationManager.distanceFilter = 100
                locationManager.allowsBackgroundLocationUpdates = true
                locationManager.pausesLocationUpdatesAutomatically = false
                locationManager.startUpdatingLocation()
            }
        }
        #endif
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.mapType = land.mapType
        drawPoly(on: uiView)
        drawImage(on: uiView)
    }

    func drawImage(on mapView: MKMapView) {
        for agroPoly in land.agroPolyMapList {
            if let img = agroPoly.images.first {
                mapView.addOverlay(img)
            }
        }
    }
    
    func drawPoly(on mapView: MKMapView) {
        mapView.removeOverlays(mapView.overlays)
        
        for agroPoly in land.agroPolyMapList {
            switch agroPoly.currentState {
            
            case .hasPoly:
                mapView.addOverlay(agroPoly.mkPoly)
                // convert map CLLocationCoordinate2D to CGPoints
                let coords = agroPoly.mkPoly.coordinates.map{ mapView.convert($0, toPointTo: mapView.superview) }
                // update our cgPoints with the coordinates
                agroPoly.updateCGPoints(coords: coords)
                
            case .fullSet:
                mapView.addOverlay(agroPoly.mkPoly)
                
            case .screenOnly:
                // convert screen CGPoint, to map CLLocationCoordinate2D
                let coords = agroPoly.cgPoints.map{ mapView.convert($0, toCoordinateFrom: mapView) }
                // update our agroPoly with the map coordinates
                agroPoly.updateCoords(coords: coords)
                mapView.addOverlay(agroPoly.mkPoly)
                // send a message to LandModel that the polygon has changed
                NotificationCenter.default.post(name: Messenger.agroNotification,
                                                object: Messenger(agroPoly.id, actionType: .addPoly))
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
//------------------------------------------------------------------------------------------
    
    final class Coordinator: NSObject, MKMapViewDelegate, UIGestureRecognizerDelegate {
        var theMap: MapView
        
        var tapGesture = UITapGestureRecognizer()
        
        init(_ theMap: MapView) {
            self.theMap = theMap
            super.init()
            self.tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
            self.tapGesture.delegate = self
            self.theMap.mapView.addGestureRecognizer(tapGesture)
        }
        
        @objc func handleTap(gestureRecognizer: UITapGestureRecognizer) {
            // position on the screen, CGPoint
            let location = gestureRecognizer.location(in: self.theMap.mapView)
            // position on the map, CLLocationCoordinate2D
            let coordinate = self.theMap.mapView.convert(location, toCoordinateFrom: self.theMap.mapView)
            if let theAgro = self.theMap.land.findAgroAt(coordinate) {
                // update the touchedPolyId
                self.theMap.land.touchedPolyId = theAgro.id
                
                if self.theMap.land.allowEditing {
                    // tapped inside a polygon, turn-on editing mode for it
                    self.theMap.land.isEditing = true
                    // send a message to LandModel that this polygon was selected for editing
                    NotificationCenter.default.post(name: Messenger.agroNotification,
                                                    object: Messenger(theAgro.id, actionType: .editPoly))
                }

                if self.theMap.land.isDeleting {
                    // send a message to ToolsBar that this polygon was selected for deletion
                    NotificationCenter.default.post(name: Messenger.agroNotification,
                                                    object: Messenger(theAgro.id, actionType: .deletePoly))
                }
            }
        }
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard let coordinates = view.annotation?.coordinate else { return }
            let span = mapView.region.span
            let region = MKCoordinateRegion(center: coordinates, span: span)
            mapView.setRegion(region, animated: true)
        }
        
        // draw the polygons, images and everything else
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.lineWidth = 3.0
            switch overlay {
            
            case is MKPolygon:
                let polygonView = MKPolygonRenderer(overlay: overlay)
                polygonView.fillColor = self.theMap.land.mapPolyFillColor
                return polygonView
                
            case is SatImage:
                if let satImg = overlay as? SatImage {
                    return AgroImgRenderer(satImg: satImg)
                }
                return renderer
                
            default:
                return renderer
            }
        }
        
        func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView,
                     didChange newState: MKAnnotationView.DragState,
                     fromOldState oldState: MKAnnotationView.DragState) {
            switch newState {
            case .starting:
                view.dragState = .dragging
            case .ending, .canceling:
                view.dragState = .none
            default: break
            }
        }

        // when zooming, update the screen coords of the polygons accordingly
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            // update all poly screen cgPoins
            for agroPoly in theMap.land.agroPolyMapList {
                // convert map CLLocationCoordinate2D to CGPoints
                let coords = agroPoly.mkPoly.coordinates.map{ mapView.convert($0, toPointTo: mapView.superview) }
                // update our cgPoints from the coordinates
                agroPoly.updateCGPoints(coords: coords)
            }
            // update the current region
            theMap.land.region = mapView.region
        }
        
    }
 
}
