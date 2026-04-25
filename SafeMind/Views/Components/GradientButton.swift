//
//  GradientButton.swift
//  SafeMind
//
//  Created by Anshuman Nitnaware on 22/03/26.
//

import SwiftUI

struct GradientButton: View {
    
    var title: String
    var icon: String? = nil
    
    var gradient: Gradient = Gradient(colors: [Color.blue, Color.purple])
    var width: CGFloat = .infinity
    var height: CGFloat = 50
    
    var isEnabled: Bool = true
    var action: () -> Void
    
    var body: some View {
        Button(action: {
            if isEnabled {
                action()
            }
        }) {
            HStack(spacing: 10) {
                
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                }
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: width)
            .frame(height: height)
            .background(
                LinearGradient(
                    gradient: gradient,
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(14)
            .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 3)
            .opacity(isEnabled ? 1.0 : 0.5)
        }
        .disabled(!isEnabled)
    }
}

#Preview {
    GradientButton(title: "String", action: { })
}
