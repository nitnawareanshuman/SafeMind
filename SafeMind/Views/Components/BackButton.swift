//
//  BackButton.swift
//  SafeMind
//
//  Created by Anshuman Nitnaware on 14/04/26.
//


import SwiftUI

struct BackButton: View {
    
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.title2)
                .foregroundColor(.white)
                .padding(10)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.2))
                )
        }
    }
}