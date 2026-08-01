//
//  MoodTopProgressBar.swift
//  SafeMind
//
//  Part of the AI Mood Check-In feature.
//
//  The thin multi-segment line under the status bar in the redesigned
//  check-in — one segment per question, filled up to (and including) the
//  question currently on screen.
//

import SwiftUI

struct MoodTopProgressBar: View {
    let totalSteps: Int
    let currentStep: Int // 0-based index of the question currently showing

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<max(totalSteps, 1), id: \.self) { index in
                Capsule()
                    .fill(index <= currentStep ? Color.white : Color.white.opacity(0.25))
                    .frame(height: 4)
                    .animation(.easeInOut(duration: 0.25), value: currentStep)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
}

#Preview {
    ZStack {
        Color.black
        MoodTopProgressBar(totalSteps: 7, currentStep: 2)
            .frame(maxHeight: .infinity, alignment: .top)
    }
    .ignoresSafeArea()
}
