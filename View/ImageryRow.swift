//
//  ImageryRow.swift
//  AgroDonkey
//
//  Created by Ringo Wathelet on 2020/08/09.
//

import SwiftUI
import AgroAPI



struct ImageryRow: View {
    
    @EnvironmentObject var land: LandModel
    
    @ObservedObject var polyImagery: PolyImagery
    
    var body: some View {
        HStack {
            Text(Date(utc: polyImagery.imagery.dt ?? 0).monthDay())
            Spacer()
            Image(systemName: "cloud").foregroundColor(.blue)
            Text(String(format: "%.0f", polyImagery.imagery.cl ?? 0) + "%")
        }.background(polyImagery.selected ? DonkeyUtils.lightBlueColor : DonkeyUtils.sysGroupGrayColor)
        .onTapGesture {
            // de-select all imagery from the currently selected poly
            land.deselectAllImagery()
            // select only this one
            polyImagery.selected = true
            land.getAllImages()
            land.refresh.toggle()
        }
    }
    
}
