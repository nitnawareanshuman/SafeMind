//
//  AvatarImage.swift
//  Irene
//
//  Created by Anshuman Nitnaware on 05/08/26.
//


//
//  AvatarImage.swift
//  Irene
//
//  Renders a user's profile photo from either a remote (http/https) URL —
//  once Supabase Storage is configured — or a local on-device `file://` URL
//  (see `LocalImageStore`, used as the working fallback today), falling back
//  to a generic person glyph when there's no photo yet. Centralized here so
//  Home, Profile, and anywhere else that shows the user's photo stay in sync.
//

import SwiftUI

struct AvatarImage: View {
    var photoURL: String?
    /// A freshly picked (not-yet-saved) image takes priority over `photoURL`,
    /// so the picker preview updates instantly.
    var overrideImage: UIImage? = nil
    var size: CGFloat = 120

    var body: some View {
        Group {
            if let overrideImage {
                Image(uiImage: overrideImage)
                    .resizable()
                    .scaledToFill()
            } else if let photoURL, !photoURL.isEmpty, let url = URL(string: photoURL) {
                if url.isFileURL {
                    if let data = try? Data(contentsOf: url), let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                    } else {
                        placeholder
                    }
                } else {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFill()
                        case .failure:
                            placeholder
                        default:
                            ProgressView()
                        }
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(.ultraThickMaterial, lineWidth: 2)
        )
    }

    private var placeholder: some View {
        Circle()
            .fill(Color(.systemGray4))
            .overlay(
                Image(systemName: "person.fill")
                    .font(.system(size: size * 0.45))
                    .foregroundColor(.white)
            )
    }
}

#Preview {
    AvatarImage(photoURL: nil, size: 100)
}
