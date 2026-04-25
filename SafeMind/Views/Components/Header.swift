//
//  Header.swift
//  SafeMind
//
//  Created by Anshuman Nitnaware on 22/03/26.
//

import SwiftUI

struct Header: View {
    @State private var title: String = "SafeMind"
    
    var body: some View {
        HStack(spacing: 0) {
            Image("SafeMindLogo")
                .resizable()
                .frame(width: 70, height: 70)
            
            Text(title)
                .font(.title)
                .fontWeight(.bold)
            
            Spacer()
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 10)
    }
}

#Preview {
    Header()
}
