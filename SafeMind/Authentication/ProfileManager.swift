import Foundation
import UIKit
import Supabase

/// Compatibility façade for existing non-auth features. New code should inject `UserManaging`.
final class ProfileManager {
    static let shared = ProfileManager()
    private init() {}

    func getUser(uid: String) async throws -> UserProfile {
        guard let id = UUID(uuidString: uid) else { throw UserManagerError.profileNotFound }
        return try await UserManager(client: supabase).fetchProfile(userID: id)
    }

    func updateUser(_ profile: UserProfile) async throws -> UserProfile {
        try await UserManager(client: supabase).updateProfile(profile)
    }

    func logActivity(uid: String, userName: String, action: UserActivity.Action, metadata: [String: String]? = nil) async throws {
        try await supabase.from("activities").insert(UserActivity(uid: uid, userName: userName, action: action, metadata: metadata)).execute()
    }

    func fetchActivities(uid: String, limit: Int = 50) async throws -> [UserActivity] {
        try await supabase.from("activities").select().eq("uid", value: uid).limit(limit).execute().value
    }

    func saveSession(uid: String, session: Session) async throws {
        try await supabase.from("sessions").insert(session).execute()
    }

    func fetchSessions(uid: String) async throws -> [Session] {
        try await supabase.from("sessions").select().eq("uid", value: uid).execute().value
    }
}

/// Image storage is intentionally separate from profile CRUD. Configure a Supabase Storage bucket
/// before enabling profile-photo uploads.
final class StorageManager {
    static let shared = StorageManager()
    private init() {}
    func uploadProfileImage(image: UIImage, uid: String) async throws -> String {
        throw UserManagerError.requestFailed("Profile image storage has not been configured.")
    }
}

struct UserActivity: Codable, Sendable {
    enum Action: String, Codable, Sendable { case music, breathing, acupressure, cbt }
    var id: String = UUID().uuidString
    var uid: String
    var userName: String
    var action: Action
    var timestamp: Date = .now
    var metadata: [String: String]?
}
