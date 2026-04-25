//
//  SplashView.swift
//  SafeMind
//
//  Created by Anshuman Nitnaware on 12/03/26.
//

import SwiftUI

struct SplashView: View {
    
    @State private var scale = 0.6
    @State private var opacity = 0.0
    
    var body: some View {
        
        ZStack {
            
            BlurBackground()
            
            VStack(spacing: 5) {
                
                Image("SafeMindLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200)
                    .scaleEffect(scale)
                    .opacity(opacity)
                
                Text("SafeMind")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color.black)
                    .opacity(opacity)
            }
        }
        .onAppear {
            
            withAnimation(.easeInOut(duration: 1.5)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}

#Preview {
    SplashView()
}
