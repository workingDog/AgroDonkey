//
//  DonkeyExtensions.swift
//  AgroDonkey
//
//  Created by Ringo Wathelet on 2020/07/31.
//


import Foundation
import CoreGraphics
import MapKit
import SwiftUI



extension MKPolygon {
    
    // determine if the coordinate is inside the polygon
    func isInside(coord: CLLocationCoordinate2D) -> Bool {
        let polygonRenderer = MKPolygonRenderer(polygon: self)
        let currentMapPoint: MKMapPoint = MKMapPoint(coord)
        let polygonViewPoint: CGPoint = polygonRenderer.point(for: currentMapPoint)
        if polygonRenderer.path == nil {
            return false
        } else {
            return polygonRenderer.path.contains(polygonViewPoint)
        }
    }
  
}

public extension MKMultiPoint {
    
    // to retrieve the coordinates from a polyline/polygon
    var coordinates: [CLLocationCoordinate2D] {
        var coords = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid, count: pointCount)
        getCoordinates(&coords, range: NSRange(location: 0, length: pointCount))
        return coords
    }
    
    // degrees to radians
    func radians(degrees: Double) -> Double {
        return degrees * Double.pi / 180
    }
    
    // calculate the area in hectares (ha) of the polygon, from SO answer code
    var area: Double {
        let kEarthRadius = 6378137.0
        guard coordinates.count > 2 else { return 0 }
        var area = 0.0

        for i in 0..<coordinates.count {
            let p1 = coordinates[i > 0 ? i - 1 : coordinates.count - 1]
            let p2 = coordinates[i]

            area += radians(degrees: p2.longitude - p1.longitude) * (2 + sin(radians(degrees: p1.latitude)) + sin(radians(degrees: p2.latitude)) )
        }

        area = -(area * kEarthRadius * kEarthRadius / 2)

        // in ha
        return max(area, -area) * 0.0001 // In order not to worry about is polygon clockwise or counterclockwise defined.
    }
   
}

extension String {
    
    func trim() -> String {
        self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
}

public extension Int {
    
    func dateFromUTC() -> Date {
        return Date(timeIntervalSince1970: TimeInterval(self))
    }
    
}

public extension Date {
    
    var utc: Int {
        return Int(self.timeIntervalSince1970)
    }
    
    init(utc: Int) {
        self = Date(timeIntervalSince1970: TimeInterval(utc))
    }
    
    func dayName(lang: String = "en") -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE"
        dateFormatter.locale = Locale(identifier: lang)
        return dateFormatter.string(from: self)
    }
    
    func dayMonthNumber(lang: String = "en") -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: lang)
        dateFormatter.dateFormat = "dd"
        return dateFormatter.string(from: self)
    }
    
    func monthDay(lang: String = "en") -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: lang)
        dateFormatter.dateFormat = "LLLL"
        let month = dateFormatter.string(from: self)
        return month + " " + dayMonthNumber(lang: lang)
    }
    
    func monthDay2(lang: String = "en") -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: lang)
        dateFormatter.dateFormat = "LLLL"
        let month = dateFormatter.string(from: self)
        return dayName(lang: lang) + ", " + month + " " + dayMonthNumber(lang: lang)
    }
    
    func hour() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH"
        return dateFormatter.string(from: self)
    }
    
    func hourMinute() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hh:mm a"
        return dateFormatter.string(from: self)
    }
    
}

// from SO
extension Array {
    
    func shiftRight(_ amount: Int = 1) -> [Element] {
        var amountMutable = amount
        assert(-count...count ~= amountMutable, "Shift amount out of bounds")
        if amountMutable < 0 { amountMutable += count }  // this needs to be >= 0
        return Array(self[amountMutable ..< count] + self[0 ..< amountMutable])
    }

    mutating func shiftRightInPlace(amount: Int = 1) {
        self = shiftRight(amount)
    }

}
