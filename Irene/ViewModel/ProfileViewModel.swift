//
//  ProfileViewModel.swift
//  Irene
//

import Foundation
import UIKit
import Combine

@MainActor
class ProfileViewModel: ObservableObject {

    @Published var user: UserProfile?
    @Published var isLoading = false
    @Published var isUploading = false           // ✅ separate upload indicator
    @Published var selectedImage: UIImage?
    @Published var showingImagePicker = false    // ✅ drives the sheet in ProfileView

    func loadUser(uid: String) {
        Task {
            isLoading = true
            defer { isLoading = false }
            do {
                user = try await ProfileManager.shared.getUser(uid: uid)
            } catch {
                print("❌ Error fetching user:", error.localizedDescription)
            }
        }
    }

    /// Saves the picked profile photo. Supabase Storage isn't configured yet
    /// (`StorageManager.uploadProfileImage` throws), so this saves to the
    /// on-device `LocalImageStore` instead — same pattern as `ActivityStore` /
    /// `MoodHistoryStore` elsewhere in the app. `onUpdated` lets the caller
    /// (ProfileView) push the new photo URL into `AuthViewModel` so Home's
    /// avatar updates immediately too.
    func updateProfile(onUpdated: ((UserProfile) -> Void)? = nil) {
        guard let user, let image = selectedImage else { return }

        isUploading = true
        defer { isUploading = false }

        guard let localURL = LocalImageStore.save(image, uid: user.uid) else {
            print("❌ Profile update failed: couldn't save image locally")
            return
        }

        var updatedUser = user
        updatedUser.photoURL = localURL
        self.user = updatedUser
        selectedImage = nil
        onUpdated?(updatedUser)

        // Best-effort sync of the rest of the profile fields to Supabase.
        // The `file://` photoURL itself is device-local and intentionally
        // not synced — a remote photo would need real Storage upload.
        Task {
            do {
                _ = try await ProfileManager.shared.updateUser(updatedUser)
            } catch {
                print("⚠️ Profile sync skipped:", error.localizedDescription)
            }
        }
    }
}
