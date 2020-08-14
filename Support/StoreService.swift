//
//  StoreService.swift
//  AgroDonkey
//
//  Created by Ringo Wathelet on 2020/08/05.
//

import Foundation
import MapKit


class StoreService {
    
    static func getAgroKey() -> String? {
        KeychainWrapper.standard.string(forKey: "donkey.agro.key")
    }
    
    static func setAgroKey(key: String) {
        KeychainWrapper.standard.set(key, forKey: "donkey.agro.key")
    }
    
    static func setRegion(region: MKCoordinateRegion) {
        let lat = Double(region.center.latitude)
        let lon = Double(region.center.longitude)
        let dLat = Double(region.span.latitudeDelta)
        let dLon = Double(region.span.longitudeDelta)
        
        UserDefaults.standard.setValue(lat, forKey: "donkey.agro.region.lat")
        UserDefaults.standard.setValue(lon, forKey: "donkey.agro.region.lon")
        UserDefaults.standard.setValue(dLat, forKey: "donkey.agro.region.dlat")
        UserDefaults.standard.setValue(dLon, forKey: "donkey.agro.region.dlon")
    }
    
    static func getRegion() -> MKCoordinateRegion {
        let lat = UserDefaults.standard.double(forKey: "donkey.agro.region.lat")
        let lon = UserDefaults.standard.double(forKey: "donkey.agro.region.lon")
        let dLat = UserDefaults.standard.double(forKey: "donkey.agro.region.dlat")
        let dLon = UserDefaults.standard.double(forKey: "donkey.agro.region.dlon")
        
        if (lat == 0.0 && lon == 0.0) {
            // Tokyo
            return MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 35.685, longitude: 139.7514),
                                      span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1))
        } else {
            return MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                                      span: MKCoordinateSpan(latitudeDelta: dLat, longitudeDelta: dLon))
        }
    }
    
}
