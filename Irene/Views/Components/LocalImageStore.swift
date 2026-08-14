//
//  LocalImageStore.swift
//  Irene
//
//  Created by Anshuman Nitnaware on 05/08/26.
//


//
//  LocalImageStore.swift
//  Irene
//
//  Working fallback for profile photos while Supabase Storage isn't
//  configured (`StorageManager.uploadProfileImage` currently just throws —
//  see Authentication/ProfileManager.swift). Saves the image to the app's
//  on-device Documents directory and hands back a stable `file://` URL that
//  can be persisted in `UserProfile.photoURL` exactly like a remote URL
//  would be. `AvatarImage` knows how to load either kind.
//

import UIKit

enum LocalImageStore {

    private static let directoryName = "ProfileImages"

    private static var directoryURL: URL {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent(directoryName, isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    /// Saves the image to disk (overwriting any previous photo for this
    /// user) and returns the `file://` URL string to store in the profile.
    @discardableResult
    static func save(_ image: UIImage, uid: String) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.85) else { return nil }
        let url = directoryURL.appendingPathComponent("\(uid).jpg")
        do {
            try data.write(to: url, options: .atomic)
            return url.absoluteString
        } catch {
            #if DEBUG
            print("❌ LocalImageStore: failed to save image:", error.localizedDescription)
            #endif
            return nil
        }
    }

    static func load(uid: String) -> UIImage? {
        let url = directoryURL.appendingPathComponent("\(uid).jpg")
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }
}
