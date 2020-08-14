//
//  MessageSender.swift
//  AgroDonkey
//
//  Created by Ringo Wathelet on 2020/08/05.
//

import Foundation
import Combine


enum ActionType: String {
    case addPoly
    case adjustPoly
    case adjustAll
    case editPoly
}

class Messenger {

    var polyId: String
    var actionType: ActionType

    init(_ id: String, actionType: ActionType) {
        self.polyId = id
        self.actionType = actionType
    }

    static let agroNotification = Notification.Name(rawValue: "com.donkey.ringo.agro")
}
