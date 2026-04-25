//
//  LoginBackground.swift
//  SafeMind
//
//  Created by Anshuman Nitnaware on 22/03/26.
//


import SwiftUI

struct LoginBackground: View {
    
    @State private var animate = false
    
    var body: some View {
        ZStack {
            
            // Base layer (slightly darker for login readability)
            LinearGradient(
                colors: [
                    Color.black.opacity(0.7),
                    Color.black.opacity(0.9)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Top glow
            Circle()
                .fill(Color.blue.opacity(0.5))
                .frame(width: 280)
                .blur(radius: 120)
                .offset(x: animate ? -100 : -140, y: animate ? -250 : -200)
            
            // Right glow
            Circle()
                .fill(Color.purple.opacity(0.5))
                .frame(width: 260)
                .blur(radius: 120)
                .offset(x: animate ? 160 : 120, y: animate ? -120 : -180)
            
            // Bottom glow (main focus for form area)
            Circle()
                .fill(Color.pink.opacity(0.4))
                .frame(width: 350)
                .blur(radius: 150)
                .offset(x: animate ? 0 : -40, y: animate ? 260 : 220)
            
            // Subtle center highlight (important for login UI)
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.15),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 300)
                .blur(radius: 80)
            
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(
                .easeInOut(duration: 8)
                .repeatForever(autoreverses: true)
            ) {
                animate.toggle()
            }
        }
    }
}

#Preview {
    LoginBackground()
}
