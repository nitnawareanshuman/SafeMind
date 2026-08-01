//
//  VerticalSliderQuestionView.swift
//  SafeMind
//
//  Part of the AI Mood Check-In feature.
//
//  The "How is your energy level?" card: a draggable vertical track that
//  snaps between the question's options, top = highest, labels running down
//  the right-hand side — same idea as the reference "language level" slider.
//

import SwiftUI

struct VerticalSliderQuestionView: View {
    let question: MoodQuestion
    let selected: MoodOption?
    var onSelect: (MoodOption) -> Void
    var onSkip: () -> Void
    var onNext: () -> Void

    private let trackHeight: CGFloat = 260
    private let trackWidth: CGFloat = 64

    private var selectedIndex: Int {
        guard let selected, let i = question.options.firstIndex(of: selected) else { return 1 }
        return i
    }

    var body: some View {
        VStack(spacing: 0) {
            Text(question.text)
                .font(.title2.bold())
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.top, 20)

            Spacer(minLength: 20)

            HStack(alignment: .center, spacing: 22) {
                slider

                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(question.options.enumerated()), id: \.element.id) { index, option in
                        Text(option.label)
                            .font(index == selectedIndex ? .headline : .subheadline)
                            .foregroundColor(index == selectedIndex ? .primary : .secondary)
                            .frame(height: rowHeight, alignment: .center)
                            .onTapGesture { onSelect(option) }
                    }
                }
            }
            .frame(height: trackHeight)
            .padding(.horizontal, 32)

            Spacer(minLength: 20)

            CheckInFooterButtons(onSkip: onSkip, onNext: onNext, nextEnabled: true)
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
        }
    }

    private var rowHeight: CGFloat { trackHeight / CGFloat(question.options.count) }

    private var thumbY: CGFloat {
        let step = trackHeight / CGFloat(max(question.options.count - 1, 1))
        return CGFloat(selectedIndex) * step
    }

    private var slider: some View {
        ZStack(alignment: .top) {
            Capsule()
                .fill(Color(.secondarySystemBackground))
                .frame(width: trackWidth, height: trackHeight)

            Capsule()
                .fill(LinearGradient(colors: [.blue, .purple], startPoint: .top, endPoint: .bottom))
                .frame(width: trackWidth, height: min(thumbY + trackWidth / 2, trackHeight))
                .animation(.easeInOut(duration: 0.2), value: selectedIndex)
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in updateSelection(forY: value.location.y) }
        )
    }

    private func updateSelection(forY y: CGFloat) {
        let step = trackHeight / CGFloat(max(question.options.count - 1, 1))
        let rawIndex = Int((y / step).rounded())
        let clamped = min(max(rawIndex, 0), question.options.count - 1)
        onSelect(question.options[clamped])
    }
}

#Preview {
    VerticalSliderQuestionView(
        question: MoodQuestion.dailyCheckInQuestions[2],
        selected: MoodQuestion.dailyCheckInQuestions[2].options[1],
        onSelect: { _ in },
        onSkip: {},
        onNext: {}
    )
}
