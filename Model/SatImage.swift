//
//  SatImage.swift
//  AgroDonkey
//
//  Created by Ringo Wathelet on 2020/08/05.
//

import Foundation
import SwiftUI
import MapKit
import AgroAPI


class SatImage: NSObject, MKOverlay, Identifiable {
    
    let coordinate: CLLocationCoordinate2D
    let boundingMapRect: MKMapRect
    
    var id: String
    var image: UIImage?
    var agroImagery: [PolyImagery]
    
    init(agroImagery: [PolyImagery], image: UIImage, coord: CLLocationCoordinate2D, rect: MKMapRect) {
        self.id = UUID().uuidString
        self.agroImagery = agroImagery
        self.image = image
        
        self.boundingMapRect = rect
        self.coordinate = coord
    }
    
    init(agroImagery: [AgroImagery], image: UIImage, coord: CLLocationCoordinate2D, rect: MKMapRect) {
        self.id = UUID().uuidString
        self.agroImagery = agroImagery.map{ PolyImagery(imagery: $0)}
        self.image = image
        
        self.boundingMapRect = rect
        self.coordinate = coord
    }
    
    init(agroImagery: [AgroImagery]) {
        self.id = UUID().uuidString
        self.agroImagery = agroImagery.map{ PolyImagery(imagery: $0)}
        self.image = nil
        
        self.boundingMapRect = MKMapRect()
        self.coordinate = CLLocationCoordinate2D()
    }
 
}
