//
//  DropDown.swift
//  AgroDonkey
//
//  Created by Ringo Wathelet on 2020/08/03.
//

import SwiftUI


struct DropDown: View {
    
    @EnvironmentObject var land: LandModel
    
    @State var expand = false
    @State var selection = ""
    
    var body: some View {
        VStack {
            VStack (spacing: 10) {
                HStack {
                    Image(systemName: "leaf").resizable().frame(width: 25, height: 22).foregroundColor(.green)
                    Text("Images")
                    Image(systemName: expand ? "chevron.up" : "chevron.down")
                        .resizable().frame(width: 10, height: 8).foregroundColor(.black)
                }.onTapGesture {
                    self.expand.toggle()
                }
                if expand {
                    ForEach(land.satImgTypes, id: \.self) { type in
                        Button(action: { actionSelection(type) }) {
                            HStack {
                                if selection == type {
                                    Image(systemName: "globe")
                                        .resizable().frame(width: 25, height: 25).foregroundColor(.blue)
                                }
                                Spacer()
                                Text(type).foregroundColor(.black)
                                Spacer()
                            }
                        }
                    }.frame(width: 190)
                }
            }
        }.padding(10)
        .background(LinearGradient(gradient:
                                    Gradient(colors: [Color(UIColor.systemGray5), .white]),
                                   startPoint: .top, endPoint: .bottom))
        .cornerRadius(15, antialiased: true)
        .shadow(color: .gray, radius: 5)
        .animation(.spring())
        .onAppear(perform: {selection = land.satImgTypes[land.satImgType]})
    }
    
    func actionSelection(_ imgType: String) {
        expand.toggle()
        selection = imgType
        if let selected = land.satImgTypes.firstIndex(of: imgType) {
            land.satImgType = selected
        }
    }
}
