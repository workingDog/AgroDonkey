//
//  AgroMapPoly.swift
//  AgroDonkey
//
//  Created by Ringo Wathelet on 2020/07/31.
//

import Foundation
import SwiftUI
import MapKit
import AgroAPI


enum ReadyState: String {
    case hasPoly
    case screenOnly
    case fullSet
}

/**
 * the main object that holds the state, the info and the points of polygons.
 */
class AgroPolyMap: ObservableObject, Identifiable {
    
    // just used to display a number after the "New field" name
    static var number = 0
    
    // is it the currently selected polygon
    var selected: Bool
    
    // to tell if the polygon points have changed due to user edition
    var hasChanged = false
    
    var currentState: ReadyState = .screenOnly
    
    // the id becomes the same as the id in agroPoly, after it has been added to the server
    var id: String
    var agroPoly: AgroPolygon
    var mkPoly: MKPolygon
    var cgPoints: [CGPoint] = []
    var images = [SatImage]()
    var stats = [AgroStatsInfo]()

 
    // Feature coordinates are (lon,lat)
    init(id: String, name: String, area: Double, feature: Feature, selected: Bool = false) {
        self.id = id
        self.agroPoly = AgroPolygon(name: name, coords: feature.geometry.coordinates)

        // must convert feature coordinates to (lat,lon) for MKPolygon
        var coords: [CLLocationCoordinate2D] = []
        if let polySet = self.agroPoly.geo_json.geometry.coordinates.first {
            for loc in polySet {
                coords.append(CLLocationCoordinate2D(latitude: loc[1], longitude: loc[0]))
            }
        }
        self.mkPoly = MKPolygon(coordinates: coords, count: coords.count)
        self.cgPoints = []
        self.currentState = .hasPoly
        self.selected = selected
    }
    
    init(name: String, cgPoints: [CGPoint], selected: Bool = false) {
        self.id = UUID().uuidString     // <--- initially id is not the same as the AgroPolygon
        self.cgPoints = cgPoints
        
        self.agroPoly = AgroPolygon(name: name, coords: [])
        self.mkPoly = MKPolygon()
        self.currentState = .screenOnly
        self.selected = selected
    }
    
    init(cgPoints: [CGPoint], selected: Bool = false) {
        AgroPolyMap.number += 1
        self.id = UUID().uuidString     // <--- initially id is not the same as the AgroPolygon
        self.cgPoints = cgPoints
        
        self.agroPoly = AgroPolygon(name: "New field \(AgroPolyMap.number)", coords: [])
        self.mkPoly = MKPolygon()
        self.currentState = .screenOnly
        self.selected = selected
    }

    // this is a new polygon, create the AgroPolygon element
    // it is now in fully fledged (fullSet state)
    func updateCoords(coords: [CLLocationCoordinate2D]) {
        // note in AgroPolygon we need (lon,lat), but in MKPolygon we have (lat,lon)
        var coordArr = coords.map{ [Double($0.longitude), Double($0.latitude)] }
        // must also close the polygon for a valid AgroPolygon
        coordArr.append(coordArr[0])
        
        agroPoly = AgroPolygon(name: agroPoly.name, coords: [coordArr])
        mkPoly = MKPolygon(coordinates: coords, count: coords.count)
        self.currentState = .fullSet
    }
    
    // update the cgPoints when we have a MKPolygon to start with, or after zooming
    func updateCGPoints(coords: [CGPoint]) {
        cgPoints = coords
        // remove the last point if already present
        if cgPoints.first == cgPoints.last {
            cgPoints = cgPoints.dropLast()
        }
        currentState = .fullSet
    }

    // when editing/dragging points
    func changePoint(_ ndx: Int, to newVal: CGPoint) {
        self.cgPoints[ndx] = newVal
        self.currentState = .screenOnly
        self.hasChanged = true
    }
    
}
