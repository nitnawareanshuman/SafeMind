//
//  ExploreView.swift
//  SafeMind
//
//  Created by Anshuman Nitnaware on 15/04/26.
//


import SwiftUI

struct ExploreView: View {
    
    var body: some View {
        NavigationStack {
            ZStack {
                BlurBackground()
                VStack(spacing: 20) {
                    
                    ExploreCard(title: "Acupressure", icon: "hand.point.up.left.fill") {
                        AccupressureView()
                    }
                    
                    ExploreCard(title: "Breathing", icon: "lungs.fill") {
                        BreathingView()
                    }
                    
                    ExploreCard(title: "CBT", icon: "brain.head.profile") {
                        CBTView()
                    }
                    
                    ExploreCard(title: "Focus", icon: "target") {
                        MusicListView(mood: "Focus")
                    }
                }
                .padding()
                .navigationTitle("Explore")
            }
        }
    }
}

struct ExploreCard<Destination: View>: View {
    
    let title: String
    let icon: String
    let destination: Destination
    
    init(title: String, icon: String, @ViewBuilder destination: () -> Destination) {
        self.title = title
        self.icon = icon
        self.destination = destination()
    }
    
    var body: some View {
        NavigationLink(destination: destination) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .frame(width: 40)
                
                Text(title)
                    .font(.headline)
                
                Spacer()
                
                Image(systemName: "chevron.right")
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(.systemGray6))
            .cornerRadius(15)
        }
    }
}

#Preview {
    ExploreView()
}
