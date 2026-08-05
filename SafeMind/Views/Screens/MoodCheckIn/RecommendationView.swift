//
//  RecommendationView.swift
//  SafeMind
//
//  Part of the AI Mood Check-In feature.
//

import SwiftUI

/// Shown once the check-in finishes: the recommended activity's message,
/// Stress / Energy / Focus rings, and a single "Start Activity" button.
struct RecommendationView: View {
    let assessment: MoodAssessment
    let recommendation: MoodRecommendation
    var onStartActivity: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            Image(systemName: recommendation.icon)
                .font(.system(size: 40))
                .foregroundColor(.blue)
                .padding(20)
                .background(.ultraThinMaterial)
                .clipShape(Circle())

            Text(recommendation.message)
                .font(.title3.bold())
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            HStack(spacing: 20) {
                CircularScoreIndicator(title: "Stress", score: assessment.stress, color: .red)
                CircularScoreIndicator(title: "Energy", score: assessment.energy, color: .orange)
                CircularScoreIndicator(title: "Focus", score: assessment.focus, color: .green)
            }

            GradientButton(title: "Start Activity", icon: "arrow.right", action: onStartActivity)
                .padding(.horizontal)
        }
        .padding()
    }
}

/// The "Analyzing your responses…" beat shown between the last answer and the result.
struct AnalyzingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.3)
            Text("Analyzing your responses…")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    ZStack {
        BlurBackground()
        RecommendationView(
            assessment: MoodAssessment(stress: 7, energy: 4, focus: 3, calmness: 3, tension: 6),
            recommendation: .breathing,
            onStartActivity: {}
        )
    }
}
