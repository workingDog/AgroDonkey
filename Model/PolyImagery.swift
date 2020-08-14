//
//  PolyImagery.swift
//  AgroDonkey
//
//  Created by Ringo Wathelet on 2020/08/09.
//

import Foundation
import AgroAPI


class PolyImagery: Identifiable, ObservableObject {
    
    let id: String
    @Published var imagery: AgroImagery
    @Published var selected: Bool
    
    init(imagery: AgroImagery, selected: Bool = false) {
        self.id = UUID().uuidString
        self.imagery = imagery
        self.selected = selected
    }
}
