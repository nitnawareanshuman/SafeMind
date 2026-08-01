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
                    selectableOption(option)
                }
            }
            .padding(.horizontal, 24)

            Spacer(minLength: 28)

            CheckInFooterButtons(onSkip: onSkip, onNext: onNext, nextEnabled: true)
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
        }
    }

    private func selectableOption(_ option: MoodOption) -> some View {
        let isSelected = selected?.id == option.id
        return Button {
            onSelect(option)
        } label: {
            Text(option.displayText)
                .font(.subheadline.weight(.medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(isSelected ? AnyShapeStyle(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)) : AnyShapeStyle(.ultraThinMaterial))
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.primary.opacity(isSelected ? 0 : 0.08), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
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
