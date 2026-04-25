//
//  UserProfile.swift
//  SafeMind
//
//  Created by Anshuman Nitnaware on 15/04/26.
//

import Foundation
import FirebaseFirestore

struct UserProfile: Codable {
    @DocumentID var uid: String?  
    var name: String
    var email: String
    var photoURL: String
    let joinedDate: Date

    var avgSession: Int
    var totalTime: Int
    var sessionsCompleted: Int
}
