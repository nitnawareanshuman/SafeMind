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
    var isSelected: Bool = false
    var action: () -> Void

    private var accentColor: Color {
        option.color ?? .accentColor
    }

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
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(isSelected ? AnyShapeStyle(accentColor) : AnyShapeStyle(.ultraThinMaterial))
                )
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(isSelected ? Color.clear : Color.primary.opacity(0.08), lineWidth: 1)
                )
                .shadow(color: isSelected ? accentColor.opacity(0.45) : .clear, radius: 12)
                .scaleEffect(isSelected ? 1.03 : 1)
                .animation(.spring(response: 0.35, dampingFraction: 0.75), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: 12) {
        OptionButton(
            option: MoodOption(
                imageName: "sleepy",
                label: "Good",
                impact: MoodImpact(stress: 3, energy: 6, focus: 6, calmness: 7, tension: 2)
            ),
            isSelected: true,
            action: {}
        )
        OptionButton(
            option: MoodOption(
                imageName: "sleepy",
                label: "Okay",
                impact: MoodImpact(stress: 3, energy: 6, focus: 6, calmness: 7, tension: 2)
            ),
            isSelected: false,
            action: {}
        )
    }
    .padding()
}
