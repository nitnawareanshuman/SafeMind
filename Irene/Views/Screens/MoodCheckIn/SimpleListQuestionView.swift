//
//  SimpleListQuestionView.swift
//  Irene
//
//  Part of the AI Mood Check-In feature.
//
//  Fallback card for questions that don't need a special layout (focus,
//  tension, sleep, stated need) — the question title plus a vertical stack of
//  `OptionButton` pills, finished off with the same Previous / Next footer
//  as every other card so the flow feels consistent end to end.
//

import SwiftUI

struct SimpleListQuestionView: View {
    let question: MoodQuestion
    let selected: MoodOption?
    var onSelect: (MoodOption) -> Void
    var onPrevious: () -> Void
    var showPrevious: Bool = false
    var onNext: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Text(question.text)
                .font(.system(size: 38, weight: .bold))
                .multilineTextAlignment(.center)
                .lineSpacing(-3)
                .foregroundColor(.primary)
                .padding(.top, 68)

            Spacer(minLength: 28)

            VStack(spacing: 12) {
                ForEach(question.options) { option in
                    OptionButton(option: option, isSelected: selected?.id == option.id) {
                        onSelect(option)
                    }
                }
            }
            .padding(.horizontal, 24)

            Spacer(minLength: 28)

            CheckInFooterButtons(onPrevious: onPrevious, onNext: onNext, nextEnabled: true, showPrevious: showPrevious)
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
        onPrevious: {},
        showPrevious: true,
        onNext: {}
    )
}
