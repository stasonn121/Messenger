//
//  FirebaseManeger.swift
//  Messenger Application
//
//  Created by user on 08.04.2020.
//  Copyright © 2020 user. All rights reserved.
//

import Foundation
import Firebase
import GoogleMaps

class FirebaseManager {
    
    static let instance = FirebaseManager()
    private let db = Firestore.firestore()
    
    private init() {}
    
    func uploadZone(nameMarker: String, centerCircle: CLLocationCoordinate2D) {
        db.collection(UIConstants.Firebase.chat).addDocument(data:
            [UIConstants.Firebase.users : [String: Any](),
            UIConstants.Firebase.latitude: (centerCircle.latitude),
            UIConstants.Firebase.longitude: (centerCircle.longitude),
            UIConstants.Firebase.nameZone: nameMarker]).collection( UIConstants.Firebase.thread)
    }
        
    func downloadZone(completion: @escaping (Result<[ZoneChat], Error>) -> Void) {
        var chatZones = [ZoneChat]()
        
        db.collection(UIConstants.Firebase.chat).getDocuments(completion: ){(querySnapshot, err) in
            if let err = err {
                completion(.failure(err))
            } else {
                for document in querySnapshot!.documents {
                    let data = document.data()
                    guard let latitude = data[UIConstants.Firebase.latitude] as? Double,
                        let longitude = data[UIConstants.Firebase.longitude] as? Double,
                        let nameZone = data[UIConstants.Firebase.nameZone] as? String else { return }
                    
                    let position = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                    let marker = GMSMarker(position: position)
                    marker.title = nameZone
                    let circle = GMSCircle(position: position, radius: 30)
                    circle.fillColor  = UIColor(red: 0/255.0, green: 0/255.0, blue: 255/255.0, alpha: 0.2)
                    circle.strokeWidth = 2;
                    circle.strokeColor = .black
                    
                    chatZones.append(ZoneChat(circle: circle, marker: marker))
                }
                completion(.success(chatZones))
            }
        }
    }
    
    func  addUserChat(username: String, userID: String, coordinate: CLLocationCoordinate2D, comletion: @escaping (Result<Bool, Error>) -> Void) {
        db.collection(UIConstants.Firebase.chat).whereField(UIConstants.Firebase.latitude, isEqualTo: coordinate.latitude).whereField(UIConstants.Firebase.longitude, isEqualTo: coordinate.longitude).getDocuments(completion: {(snaphot,error) in
            let data = snaphot?.documents.first?.data()
            var users = [String: Any]()
            var user = [String: Any]()
            user["name"] = username
            user["id"] = userID
            
            if let userFB = data?[UIConstants.Firebase.users] as? [String: Any] {
                users = userFB
                users["\(userID)"] = user
            }
                   
            snaphot?.documents.first?.reference.updateData([UIConstants.Firebase.users: users])
            comletion(.success(true))
        })
    }
    
    func leaveChat(userID: String, x: Double, y: Double) {
        db.collection(UIConstants.Firebase.chat).whereField("latitude", isEqualTo: x).whereField("longitude", isEqualTo: y).getDocuments(completion: { (snaphot,error) in
            let document = snaphot?.documents.first
            let data = snaphot?.documents.first?.data()
            var users = [String: Any]()
            
            if let userFB = data?[UIConstants.Firebase.users] as? [String: Any] {
                users = userFB
            }
            document?.reference.updateData([UIConstants.Firebase.users: users.filter({$0.key != "\(userID)"})])
        })
    }
    
    func loadMessage(x: Double, y: Double, completion: @escaping (Result<[Message], Error>) -> Void) {
        db.collection(UIConstants.Firebase.chat).whereField("latitude", isEqualTo: x).whereField("longitude", isEqualTo: y).getDocuments(completion: { (snaphot,error) in
            snaphot?.documents.first?.reference.collection(UIConstants.Firebase.thread).getDocuments(completion: {
                (snapshot,error) in
                var fbMessages = [Message]()
                for doc in snapshot!.documents {
                    guard let id = doc.data()[UIConstants.Message.id] as? String,
                        let content = doc.data()[UIConstants.Message.content] as? String,
                        let created = doc.data()[UIConstants.Message.created] as? Timestamp,
                        let senderID = doc.data()[UIConstants.Message.senderID] as? String,
                        let senderName = doc.data()[UIConstants.Message.senderName] as? String else { return }
                    let message = Message(id: id, content: content, created: created, senderID: senderID, senderName: senderName)
                    fbMessages.append(message)
                }
                    
                fbMessages = fbMessages.sorted(by: {(first, second) in
                    let firstDate = first.created.dateValue()
                    let secondDate = second.created.dateValue()
                    return firstDate < secondDate
                })
                
                completion(.success(fbMessages))
                    
            })
         })
        
    }
    
    func saveMessage(message: Message, x: Double, y: Double, completion: @escaping (Result<Bool, Error>) -> Void) {
        let data: [String: Any] = [
            UIConstants.Message.content: message.content,
            UIConstants.Message.created: message.created,
            UIConstants.Message.id: message.id,
            UIConstants.Message.senderID: message.senderID,
            UIConstants.Message.senderName: message.senderName
        ]
        
        db.collection(UIConstants.Firebase.chat).whereField("latitude", isEqualTo: x).whereField("longitude", isEqualTo: y).getDocuments(completion: { (snaphot,error) in
            snaphot?.documents.first?.reference.collection(UIConstants.Firebase.thread).addDocument(data: data)
            
            if let error = error {
                completion(.failure(error))
                print("Error Sending message: \(error)")
                return
            } else {
                completion(.success(true))
            }
            
        })
    }
    
    func deleteMessage(message: Message, x: Double, y: Double) {
        db.collection(UIConstants.Firebase.chat).whereField("latitude", isEqualTo: x).whereField("longitude", isEqualTo: y).getDocuments(completion: { (snaphot,error) in
                   snaphot?.documents.first?.reference.collection(UIConstants.Firebase.thread).whereField(UIConstants.Message.id, isEqualTo: message.id).getDocuments(completion: {
                            (snapshot, error) in
                            snapshot?.documents.first?.reference.delete()
                   })
            })
    }
    
    func allUsers(x: Double, y: Double, completion: @escaping (Result<[String], Error>) -> Void) {
        db.collection(UIConstants.Firebase.chat).whereField("latitude", isEqualTo: x).whereField("longitude", isEqualTo: y).getDocuments(completion: { (snaphot,error) in
            if let err = error {
                completion(.failure(err))
            } else {
                for document in snaphot!.documents {
                    let data = document.data()
                    guard let users = data[UIConstants.Firebase.users] as? [String: Any] else { return }
                    var names = [String]()
                    for user in users {
                        if let us = user.value as? [String: Any],
                            let name = us["name"] as? String {
                            names.append(name)
                        }
                    }
                    completion(.success(names))
                }
            }
        }
    )}
}

