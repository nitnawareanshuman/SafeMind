//
//  OptionButton.swift
//  SafeMind
//
//  Part of the AI Mood Check-In feature.
//

import SwiftUI

/// A single tappable answer choice shown below the current AI question.
struct OptionButton: View {
    let option: MoodOption
    var action: () -> Void

    var body: some View {
        Button(action: action) {
        
            if let image = option.imageName {

                Image(image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 84,height: 84)

            }
            Text(option.label)
                .font(.title2.weight(.medium))
                .frame(maxWidth: .infinity)
                .frame(height: 45)
                .padding(.vertical, 14)
                .background(.ultraThinMaterial)
                .foregroundColor(.primary)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    OptionButton(
        option: MoodOption(
            imageName: "sleepy",
            label: "Good",
            impact: MoodImpact(stress: 3, energy: 6, focus: 6, calmness: 7, tension: 2)
        ),
        action: {}
    )
    .padding()
}
