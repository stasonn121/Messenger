//
//  Message.swift
//  Messenger Application
//
//  Created by user on 09.04.2020.
//  Copyright © 2020 user. All rights reserved.
//

import Firebase
import MessageKit

struct Message {
    var id: String
    var content: String
    var created: Timestamp
    var senderID: String
    var senderName: String
}

extension Message: MessageType {
    var sender: SenderType {
        return Sender(senderId: senderID, displayName: senderName)
    }
    var messageId: String {
        return id
    }
    var sentDate: Date {
        return created.dateValue()
    }
    var kind: MessageKind {
        return .text(content)
    }
}
