//
//  ToolsBar.swift
//  AgroDonkey
//
//  Created by Ringo Wathelet on 2020/08/02.
//

import Foundation
import SwiftUI
import Combine
import MapKit
import CoreLocation


struct ToolsBar: View {
    
    @EnvironmentObject var land: LandModel
    
    @State private var mapType: Int = 0
    @State private var mapTypes = ["Map", "Earth", "All"]
    
    let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    @State private var color = Color.blue

    @State private var editText = "Edit off"
    @State var showsAlert = false
    

    var body: some View {
        Group {
            if DonkeyUtils.isiPhone {
                VStack (alignment: .leading) {
                    polyTools
                    mapTools
                }.frame(height: 160)
            } else {
                HStack {
                    polyTools
                    Spacer()
                    mapTools
                }.frame(height: 130)
            }
        }.padding(.horizontal, 5)
        .background(RoundedRectangle(cornerRadius: 15)
                        .stroke(lineWidth: 2)
                        .foregroundColor(Color.blue)
                        .background(Color(UIColor.systemGray6))
                        .padding(1))
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .contentShape(Rectangle())
        .alert(isPresented: self.$showsAlert) {
            Alert(title: Text("Delete " + land.touchedPolyName + "?"),
                  message: Text("This action cannot be undone"),
                  primaryButton: .destructive(Text("Delete")) { self.doDeletePoly() },
                  secondaryButton: .cancel() { land.touchedPolyId = ""; land.isDeleting = false })
        }
        .onReceive(NotificationCenter.default.publisher(for: Messenger.agroNotification)) { messenger in
            if let msg = messenger.object as? Messenger, ActionType.deletePoly == msg.actionType {
                showsAlert = true
            }
        }
    }
    
    var mapTools: some View {
        HStack {
            if !DonkeyUtils.isiPhone {  Spacer() }
            Picker(selection: Binding<Int> (
                get: {self.mapType},
                set: {
                    self.mapType = $0
                    self.land.mapType = self.getMapType()
                }
            ), label: Text("")) {
                ForEach(0 ..< mapTypes.count) {
                    Text(self.mapTypes[$0])
                }
            }.pickerStyle(SegmentedPickerStyle())
            .labelsHidden()
            .frame(width: 170, height: 50)
            .clipped()
            if DonkeyUtils.isiPhone {  Spacer() }
        }
    }
    
    var polyTools: some View {
        HStack (spacing: 10) {
            editPolyButton
            addPolyButton
            deletePolyButton
            Text(land.touchedPolyName).foregroundColor(.green)
        }.padding(5)
    }
    
    var deletePolyButton: some View {
        Button(action: {self.deletePoly()}) {
            VStack {
                Image(systemName: "flame")
                    .resizable()
                    .frame(width: 35, height: 35)
                    .foregroundColor(land.isDeleting ? color : .blue)
                    .onReceive(timer) { _ in
                        if land.isDeleting {
                            color = color == .blue ? .red : .blue
                        }
                    }
                Text("Delete").font(.caption).foregroundColor(land.isDeleting ? color : .blue)
            }.frame(width: 70, height: 70)
        }.buttonStyle(GrayButtonStyle())
        .scaleEffect(land.isDeleting ? 1.2 : 1.0)
    }

    var editPolyButton: some View {
        Button(action: {self.doEditPoly()}) {
            VStack {
                Image(systemName: "skew")
                    .resizable()
                    .frame(width: 35, height: 35)
                    .foregroundColor(land.allowEditing ? color : .blue)
                    .onReceive(timer) { _ in
                        if land.allowEditing {
                            color = color == .blue ? .red : .blue
                        }
                    }
                Text(land.allowEditing ? "Edit on" : "Edit off").font(.caption).foregroundColor(land.allowEditing ? color : .blue)
            }.frame(width: 70, height: 70)
        }.buttonStyle(GrayButtonStyle())
        .scaleEffect(land.allowEditing ? 1.2 : 1.0)
    }
    
    func doEditPoly() {
        land.allowEditing.toggle()
        editText = land.allowEditing ? "Edit on" : "Edit off"
        if !land.allowEditing { land.isEditing = false  }
        land.isAdding = false
        // when finished editing, send a message to update all polygons on the server
        if !land.allowEditing {
            NotificationCenter.default.post(name: Messenger.agroNotification,
                                            object: Messenger("", actionType: .adjustAll))
        }
    }
  
    var addPolyButton: some View {
        Button(action: {self.doAddPoly()}) {
            VStack {
                Image(systemName: "squareshape.controlhandles.on.squareshape.controlhandles")
                    .resizable()
                    .frame(width: 35, height: 35)
                    .foregroundColor(land.isAdding ? color : .blue)
                    .onReceive(timer) { _ in
                        if land.isAdding {
                            color = color == .blue ? .red : .blue
                        }
                    }
                Text("Add").font(.caption).foregroundColor(land.isAdding ? color : .blue)
            }.frame(width: 70, height: 70)
        }
        .buttonStyle(GrayButtonStyle())
        .scaleEffect(land.isAdding ? 1.2 : 1.0)
    }
    
    func doAddPoly() {
        land.isAdding.toggle()
        land.isEditing = false
        // add poly only when user tap to deactivate the "Add" button
        if !land.isAdding && land.points.count >= 3 {
            // create a basic polygon with just the screen coords
            let agroPoly = AgroPolyMap(cgPoints: land.points)
            land.agroPolyMapList.append(agroPoly)
            land.points.removeAll()
        }
    }
    
    func getMapType() -> MKMapType {
        switch mapType {
        case 0: return .standard
        case 1: return .satellite
        case 2: return .hybrid
        default:
            return .standard
        }
    }
    
    private func doDeletePoly() {
        if let ndx = land.agroPolyMapList.firstIndex(where: { $0.id == land.touchedPolyId}) {
            land.agroPolyMapList.remove(at: ndx)
            // delete the polygon from the server
            // land.agroProvider.deletePoly(id: land.touchedPolyId) { _ in }
            land.touchedPolyId = ""
            land.isDeleting = false
        }
    }
    
    private func deletePoly() {
        land.isDeleting.toggle()
        if land.isDeleting {
            land.touchedPolyId = ""
            showsAlert = false
        } else {
            if land.touchedPolyId != "" {
                showsAlert = true
            }
        }
    }

}
