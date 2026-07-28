//
//  ProfileViewModel.swift
//  SafeMind
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

    /// Upload profile media only after configuring a Supabase Storage bucket.
    func updateProfile() {
        guard let user else { return }

        Task {
            isUploading = true
            defer { isUploading = false }

            do {
                var updatedUser = user

                // ✅ Upload photo if one was picked
                if let image = selectedImage {
                    let url = try await StorageManager.shared.uploadProfileImage(image: image, uid: user.uid)
                    updatedUser.photoURL = url
                    selectedImage = nil   // clear after upload
                }


            } catch {
                print("❌ Profile update failed:", error.localizedDescription)
            }
        }
    }
}
