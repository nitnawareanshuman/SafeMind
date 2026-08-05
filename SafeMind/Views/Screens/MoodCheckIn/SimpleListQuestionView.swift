//
//  SimpleListQuestionView.swift
//  SafeMind
//
//  Part of the AI Mood Check-In feature.
//
//  Fallback card for questions that don't need a special layout (focus,
//  tension, sleep, stated need) — the question title plus a vertical stack of
//  `OptionButton` pills, finished off with the same Skip / Next footer as
//  every other card so the flow feels consistent end to end.
//

import SwiftUI

struct SimpleListQuestionView: View {
    let question: MoodQuestion
    let selected: MoodOption?
    var onSelect: (MoodOption) -> Void
    var onSkip: () -> Void
    var onNext: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Text(question.text)
                .font(.title2.bold())
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.top, 24)

            Spacer(minLength: 28)

            VStack(spacing: 12) {
                ForEach(question.options) { option in
                    OptionButton(option: option) {
                        onSelect(option)
                    }
                }
            }
            .padding(.horizontal, 24)

            Spacer(minLength: 28)

            CheckInFooterButtons(onSkip: onSkip, onNext: onNext, nextEnabled: true)
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
        }
    }
}

#Preview {
    SimpleListQuestionView(
        question: MoodQuestion.dailyCheckInQuestions[3],
        selected: nil,
        onSelect: { _ in },
        onSkip: {},
        onNext: {}
    )
}
