//
//  PolyListRow.swift
//  AgroDonkey
//
//  Created by Ringo Wathelet on 2020/08/02.
//

import SwiftUI
import AgroAPI


struct PolyListRow: View {
    
    @EnvironmentObject var land: LandModel
    
    @State var thePoly: AgroPolyMap
    @State var polyName = ""
    
    
    var body: some View {
        HStack {
            TextField("", text: $polyName).frame(width: 200)
            Spacer()
            Text(String(format: "%.1f", thePoly.mkPoly.area) + " ha")
        }.textFieldStyle(RoundedBorderTextFieldStyle())
        .background(thePoly.selected ? DonkeyUtils.lightBlueColor : DonkeyUtils.sysGroupGrayColor)
        .onAppear(perform: {polyName = thePoly.agroPoly.name})
        .onDisappear() {
            if polyName != thePoly.agroPoly.name {
                print("\n----> PolyListRow updatePoly FAKE updating name on server: \(polyName)")
                // self.land.agroProvider.updatePoly(id: thePoly.id, name: polyName) { _ in }
            }
        }
    }
 
}
