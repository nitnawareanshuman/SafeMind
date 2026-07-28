//
//  UserProfile.swift
//  SafeMind
//
//  Created by Anshuman Nitnaware on 15/04/26.
//

import Foundation

/// The application-owned data stored in the `profiles` Supabase table.
/// `id` matches the user's `auth.users.id` value.
struct UserProfile: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    var name: String
    var email: String
    var photoURL: String
    let joinedDate: Date
    var avgSession: Int
    var totalTime: Int
    var sessionsCompleted: Int

    enum CodingKeys: String, CodingKey {
        case id, name, email
        case photoURL = "photo_url"
        case joinedDate = "joined_date"
        case avgSession = "avg_session"
        case totalTime = "total_time"
        case sessionsCompleted = "sessions_completed"
    }

    init(id: UUID, name: String, email: String, photoURL: String = "", joinedDate: Date = .now, avgSession: Int = 0, totalTime: Int = 0, sessionsCompleted: Int = 0) {
        self.id = id
        self.name = name
        self.email = email
        self.photoURL = photoURL
        self.joinedDate = joinedDate
        self.avgSession = avgSession
        self.totalTime = totalTime
        self.sessionsCompleted = sessionsCompleted
    }

    /// Compatibility helper for existing views that use String identifiers.
    var uid: String { id.uuidString }
}
