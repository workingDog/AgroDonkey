//
//  AgroDonkeyApp.swift
//  AgroDonkey
//
//  Created by Ringo Wathelet on 2020/07/18.
//

import SwiftUI

@main
struct AgroDonkeyApp: App {
    
    var land = LandModel()
    
    var body: some Scene {
        WindowGroup {
            HomeView().environmentObject(self.land)
        }
    }
}
