//
//  SatelliteView.swift
//  AgroDonkey
//
//  Created by Ringo Wathelet on 2020/08/03.
//

import Foundation
import SwiftUI
import MapKit
import CoreLocation
import UserNotifications
import Combine

struct SatelliteView: View {
    
    @EnvironmentObject var land: LandModel
    
    
    var body: some View {
        ZStack (alignment: .topLeading) {
            MapView().edgesIgnoringSafeArea(.all)
            // add a transparent glass view on top of the map to be used only during adding or editing polygons
            if land.isEditing || land.isAdding {
                GlassView()
            }
            // the tools bar floating above the map and the glass view
            ToolsBar()
            HStack {
                Spacer()
                VStack {
                    Text(land.satImgTypes[land.satImgType])
                    DropDown()
                }
                if !DonkeyUtils.isiPhone { Spacer() }
            }.padding(.top, DonkeyUtils.isiPhone ? 50 : 20)
        }
    }

}
