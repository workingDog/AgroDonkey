//
//  HomeView.swift
//  AgroDonkey
//
//  Created by Ringo Wathelet on 2020/07/19.
//

import Foundation
import SwiftUI
import Combine
import MapKit
import AgroAPI


struct HomeView: View {
    
    @EnvironmentObject var land: LandModel

    var body: some View {
        TabView {
            SatelliteView()
                .tabItem {
                    Image(systemName: "globe")
                }
            PolyInfoView()
                .tabItem {
                    Image(systemName: "info.circle")
                }
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape")
                }
        }.onAppear(perform: loadData)
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            StoreService.setRegion(region: land.region)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            land.region = StoreService.getRegion()
        }
    }
    
    func loadData() {
        let theKey = StoreService.getAgroKey() ?? "your key"
        land.agroProvider = AgroProvider(apiKey: theKey)
        land.getAllAgroPoly()  
    }
    
}
