//
//  Header.swift
//  SafeMind
//
//  Created by Anshuman Nitnaware on 22/03/26.
//

import SwiftUI

struct Header: View {
    let photoURL: String?
    let uid: String

    var body: some View {
        HStack {
            Image("SafeMindLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)

            Text("SafeMind")
                .font(.title.bold())

            Spacer()

            NavigationLink {
                ProfileView(uid: uid)
            } label: {
                AvatarImage(photoURL: photoURL, size: 56)
            }
            .buttonStyle(.plain)
        }
    }
}

