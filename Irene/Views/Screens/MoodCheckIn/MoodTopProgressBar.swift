//
//  MoodTopProgressBar.swift
//  Irene
//
//  Part of the AI Mood Check-In feature.
//
//  The thin multi-segment line under the status bar in the redesigned
//  check-in — one segment per question, filled up to (and including) the
//  question currently on screen. Navigation now lives entirely in the
//  bottom footer (Previous / Next), so this bar is a pure progress
//  indicator with no back/forward controls.
//

import SwiftUI

struct MoodTopProgressBar: View {
    let totalSteps: Int
    let currentStep: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<max(totalSteps, 1), id: \.self) { index in
                Capsule()
                    .fill(index <= currentStep ? Color.primary : Color.primary.opacity(0.18))
                    .frame(height: 4)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .animation(.easeInOut(duration: 0.25), value: currentStep)
    }
}

#Preview {
    ZStack {
        Color.black
        MoodTopProgressBar(totalSteps: 5, currentStep: 2)
    }
}
