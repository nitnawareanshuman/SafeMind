//
//  ProgressIndicator.swift
//  Irene
//
//  Part of the AI Mood Check-In feature.
//

import SwiftUI

/// Linear progress bar + "Question X of Y" label shown above the chat.
struct ProgressIndicator: View {
    let current: Int   // 1-based
    let total: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Question \(current) of \(total)")
                .font(.caption)
                .foregroundColor(.secondary)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.primary.opacity(0.08))
                    Capsule()
                        .fill(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * CGFloat(current) / CGFloat(max(total, 1)))
                        .animation(.easeInOut(duration: 0.35), value: current)
                }
            }
            .frame(height: 6)
        }
    }
}

/// Circular 0–10 score ring used on the recommendation screen (Stress / Energy / Focus).
struct CircularScoreIndicator: View {
    let title: String
    let score: Double // 0...10
    var color: Color = .blue

    private var fraction: Double { min(max(score / 10, 0), 1) }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.15), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: fraction)
                    .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.8), value: fraction)
                Text(String(format: "%.0f", score))
                    .font(.headline)
            }
            .frame(width: 64, height: 64)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    VStack(spacing: 24) {
        ProgressIndicator(current: 2, total: 6)
        HStack(spacing: 20) {
            CircularScoreIndicator(title: "Stress", score: 7, color: .red)
            CircularScoreIndicator(title: "Energy", score: 4, color: .orange)
            CircularScoreIndicator(title: "Focus", score: 3, color: .green)
        }
    }
    .padding()
}
