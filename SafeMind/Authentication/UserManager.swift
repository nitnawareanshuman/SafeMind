import Foundation
import Supabase

/// Errors produced while reading or writing application profiles.
enum UserManagerError: LocalizedError, Equatable {
    case profileNotFound
    case invalidName
    case requestFailed(String)

    var errorDescription: String? {
        switch self {
        case .profileNotFound: return "Your profile could not be found."
        case .invalidName: return "Enter a name to create your profile."
        case let .requestFailed(message): return message
        }
    }
}

/// Profile persistence contract, suitable for dependency injection and unit testing.
protocol UserManaging: Sendable {
    func createProfile(userID: UUID, name: String, email: String) async throws -> UserProfile
    func fetchProfile(userID: UUID) async throws -> UserProfile
    func updateProfile(_ profile: UserProfile) async throws -> UserProfile
}

/// Performs CRUD operations against Supabase's `profiles` table.
final class UserManager: UserManaging, @unchecked Sendable {
    private let client: SupabaseClient

    init(client: SupabaseClient) {
        self.client = client
    }

    func createProfile(userID: UUID, name: String, email: String) async throws -> UserProfile {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { throw UserManagerError.invalidName }

        let profile = UserProfile(id: userID, name: trimmedName, email: email)
        do {
            let saved: UserProfile = try await client.from("profiles").insert(profile).select().single().execute().value
            return saved
        } catch {
            throw UserManagerError.requestFailed(error.localizedDescription)
        }
    }

    func fetchProfile(userID: UUID) async throws -> UserProfile {
        do {
            let profile: UserProfile = try await client.from("profiles").select().eq("id", value: userID.uuidString).single().execute().value
            return profile
        } catch {
            throw UserManagerError.profileNotFound
        }
    }

    func updateProfile(_ profile: UserProfile) async throws -> UserProfile {
        do {
            let updated: UserProfile = try await client.from("profiles").update(profile).eq("id", value: profile.id.uuidString).select().single().execute().value
            return updated
        } catch {
            throw UserManagerError.requestFailed(error.localizedDescription)
        }
    }
}
