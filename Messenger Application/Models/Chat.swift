//
//  Chat.swift
//  Messenger Application
//
//  Created by user on 09.04.2020.
//  Copyright © 2020 user. All rights reserved.
//

import Foundation

struct Chat {
    var users: [String]
    var dictionary: [String: Any ] {
        return ["users": users]
    }
}

extension Chat {
    init?(dictionary: [String:Any]) {
    guard let chatUsers = dictionary["users"] as? [String] else {return nil}
    self.init(users: chatUsers)
    }
}
