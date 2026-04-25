//
//  ProfileManager.swift
//  SafeMind
//
//  Created by Anshuman Nitnaware on 15/04/26.
//

import FirebaseFirestore
import FirebaseStorage
import UIKit

final class ProfileManager {
    
    static let shared = ProfileManager()
    private let db = Firestore.firestore()
    
    private init() {}
    
    // SAVE USER
    func createUser(profile: UserProfile) async throws {
        guard let uid = profile.uid else {
            throw URLError(.badURL)
        }
        try db.collection("users").document(uid).setData(from: profile)
    }
    
    // FETCH USER
    func getUser(uid: String) async throws -> UserProfile {
        let document = try await db.collection("users").document(uid).getDocument()
        return try document.data(as: UserProfile.self)
    }
}

final class StorageManager {
    
    static let shared = StorageManager()
    private let storage = Storage.storage()
    
    private init() {}
    
    func uploadProfileImage(image: UIImage, uid: String) async throws -> String {
        guard let data = image.jpegData(compressionQuality: 0.5) else {
            throw URLError(.badURL)
        }
        
        let ref = storage.reference().child("profile_images/\(uid).jpg")
        
        _ = try await ref.putDataAsync(data)
        let url = try await ref.downloadURL()
        
        return url.absoluteString
    }
}
import Foundation

// MARK: - User Activity Model
struct UserActivity: Codable {
    enum Action: String, Codable {
        case music
        case breathing
        case acupressure
        case cbt
    }

    var id: String = UUID().uuidString
    var uid: String
    var userName: String
    var action: Action
    var timestamp: Date = Date()
    var metadata: [String: String]? // optional extra info, e.g., track name, duration, etc.
}

extension ProfileManager {

    // MARK: - Activity Logging
    /// Logs an activity under users/{uid}/activities/{activityId}
    func logActivity(uid: String, userName: String, action: UserActivity.Action, metadata: [String: String]? = nil) async throws {
        let activity = UserActivity(uid: uid, userName: userName, action: action, metadata: metadata)
        try db.collection("users").document(uid)
            .collection("activities")
            .document(activity.id)
            .setData(from: activity)
    }

    /// Fetches recent activities for a user, ordered by timestamp desc, with an optional limit
    func fetchActivities(uid: String, limit: Int = 50) async throws -> [UserActivity] {
        let snapshot = try await db.collection("users").document(uid)
            .collection("activities")
            .order(by: "timestamp", descending: true)
            .limit(to: limit)
            .getDocuments()
        return try snapshot.documents.map { try $0.data(as: UserActivity.self) }
    }
    
    func saveSession(uid: String, session: Session) async throws {
        try Firestore.firestore()
            .collection("users")
            .document(uid)
            .collection("sessions")
            .document(session.id)
            .setData(from: session)
    }
    
    func fetchSessions(uid: String) async throws -> [Session] {
        let snapshot = try await db.collection("users")
            .document(uid)
            .collection("sessions")
            .order(by: "date", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc in
            try? doc.data(as: Session.self)
        }
    }
}

