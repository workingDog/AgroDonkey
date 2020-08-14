//
//  SettingsView.swift
//  AgroDonkey
//
//  Created by Ringo Wathelet on 2020/08/05.
//

import SwiftUI
import AgroAPI


struct SettingsView: View {
    
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    @EnvironmentObject var land: LandModel
    
    @State var theKey = "your Agro API key"
    
    var body: some View {
        VStack (alignment: .leading, spacing: 30) {
            HStack {
                Spacer()
                Text("Settings").font(.title).padding(30)
                Spacer()
            }
            keyView
            datesPickerView
            Spacer()
        }.onAppear(perform: loadData)
        .frame(minWidth: 300, idealWidth: 400, maxWidth: .infinity)
    }

    var datesPickerView: some View {
        VStack (alignment: .leading) {
            Text("Satellite image retrieving dates").padding(10)
            HStack {
                Text("Start")
                Spacer()
                Text("End")
            }.padding(.horizontal, 60)
            HStack {
                DatePicker("", selection: self.$land.startImageSearch, displayedComponents: .date).labelsHidden().datePickerStyle(CompactDatePickerStyle())
                Spacer()
                DatePicker("", selection: self.$land.endImageSearch, displayedComponents: .date).labelsHidden().datePickerStyle(CompactDatePickerStyle())
            }.frame(height: 50)
        }
    }

    var keyView: some View {
        VStack (alignment: .leading) {
            Text("Agro API key")
            HStack {
                TextField("Agro API key", text: $theKey).foregroundColor(.blue)
                    .textFieldStyle(CustomTextFieldStyle())
                    .padding(30)
                
                Button(action: {self.onSave()}) {
                    Text("Save").padding(20).foregroundColor(Color.primary)
                }.cornerRadius(40)
                .overlay(RoundedRectangle(cornerRadius: 40).stroke(lineWidth: 2).foregroundColor(.green))
                .padding(.horizontal, 10)
            }.background(RoundedRectangle(cornerRadius: 15)
                            .stroke(lineWidth: 2)
                            .foregroundColor(Color.black)
                            .background(Color(UIColor.systemGray6))
                            .padding(1))
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .contentShape(Rectangle())
        }.padding(5)
    }
    
    func loadData() {
        // paste the key from the pasteboard
//        if let theString = UIPasteboard.general.string {
//            theKey = theString
//        }
    }
    
    func onSave() {
        StoreService.setAgroKey(key: theKey)
        self.land.agroProvider = AgroProvider(apiKey: theKey)
        self.land.getAllAgroPoly()
        // to go back to the previous view
        self.presentationMode.wrappedValue.dismiss()
    }
    
}
