//
//  DonkeyUtils.swift
//  AgroDonkey
//
//  Created by Ringo Wathelet on 2020/07/19.
//

import Foundation
import SwiftUI
import MapKit
import CoreLocation
import UIKit
import PDFKit
import EventKit
import AgroAPI



struct GrayButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .foregroundColor(Color.white)
            .padding(5)
            .background(LinearGradient(gradient: Gradient(colors: [Color.white, Color(UIColor.systemGray4)]), startPoint: .top, endPoint: .bottom))
            .cornerRadius(15.0)
    }
}

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.callout)
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 15).strokeBorder(Color.blue, lineWidth: 2))
    }
}


class DonkeyUtils {
 
    static let isiPhone = UIDevice.current.userInterfaceIdiom == .phone
    
    static let kelvin = 273.15
    
    static let weekDayNumbers = [
        "Sunday": 0,
        "Monday": 1,
        "Tuesday": 2,
        "Wednesday": 3,
        "Thursday": 4,
        "Friday": 5,
        "Saturday": 6,
    ]

    // return the sorted names of all week days, starting with today
    static func shiftedDaysFromToday() -> [String] {
        let today = Date().dayName()
        let days = [String] (weekDayNumbers.keys)
        let offset = weekDayNumbers[today] ?? 7
        return DonkeyUtils.sortedDays(days).shiftRight(offset)
    }
    
    // return the sorted names of all week days, starting with Sunday
    static func sortedDays(_ arr: [String]) -> [String] {
        return arr.sorted(by: { (weekDayNumbers[$0] ?? 7) < (weekDayNumbers[$1] ?? 7) })
    }
    
    static let txtColor = Color.primary
    static let bckColor = Color(UIColor.systemBackground)
    static let blueSysColor = Color(UIColor.systemBlue)
    static let redSysColor = Color(UIColor.systemRed)
    static let lightBlueColor = Color(UIColor.systemTeal)
    static let lightGreenColor = Color(UIColor.systemGreen)
    static let lightGray = Color(UIColor.systemGray6)
    static let sysGroupGrayColor = Color(UIColor.systemGroupedBackground)
    
    static func formattedDate(utc: Int, offset: Int = 0) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: offset)
        dateFormatter.dateFormat = "yyyy-MM-dd HH"
        return dateFormatter.string(from: utc.dateFromUTC())
    }
    
    static func formattedFullDate(utc: Int, offset: Int = 0) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: offset)
        dateFormatter.dateFormat = "yyyy-MM-dd hh:mm:ss"
        return dateFormatter.string(from: Date(utc: utc))
    }
    
    static func hourFormattedDate(utc: Int, offset: Int = 0) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hh:mm a"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: offset)
        return dateFormatter.string(from: utc.dateFromUTC())
    }
    
    static func timezoneOffset(at poly: AgroPolyMap, completion: @escaping (Int) -> Void) {
        let location = CLLocation(latitude: poly.mkPoly.coordinate.latitude, longitude: poly.mkPoly.coordinate.longitude)
        let geoCoder = CLGeocoder()
        geoCoder.reverseGeocodeLocation(location) { (placemarks, err) in
            if let placemark = placemarks?[0] {
                if let offset = placemark.timeZone?.secondsFromGMT() {
                    return completion(offset)
                }
            }
        }
    }
    
    static func timezone(at poly: AgroPolyMap, completion: @escaping (TimeZone) -> Void) {
        let location = CLLocation(latitude: poly.mkPoly.coordinate.latitude, longitude: poly.mkPoly.coordinate.longitude)
        let geoCoder = CLGeocoder()
        geoCoder.reverseGeocodeLocation(location) { (placemarks, err) in
            if let placemark = placemarks?[0] {
                if let tz = placemark.timeZone {
                    return completion(tz)
                }
            }
        }
    }
    
    static func toCelsius(_ ktemp: Double?) -> String {
        return ktemp != nil ? String(format: "%.0f", (ktemp! - DonkeyUtils.kelvin).rounded())+"°" : "-°"
    }

}
