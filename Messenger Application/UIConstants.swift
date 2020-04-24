//
//  UIConstants.swift
//  Messenger Application
//
//  Created by user on 14.04.2020.
//  Copyright © 2020 user. All rights reserved.
//

import Foundation

enum UIConstants {
    enum sequeIndificator {
        static let messager = "messager"
        static let listUsers = "listUsers"
        static let map = "map"
    }
    
    enum Image {
        static let person = "person"
    }
    
    enum Cell {
        static let cell = "Cell"
    }
  
    enum Firebase {
        static let users = "users"
        static let latitude = "latitude"
        static let longitude = "longitude"
        static let nameZone = "nameZone"
        static let thread = "thread"
        static let chat = "Chat"
    }
    
    enum Message {
        static let id = "id"
        static let content = "content"
        static let created = "created"
        static let senderID = "senderID"
        static let senderName = "senderName"
    }
}
