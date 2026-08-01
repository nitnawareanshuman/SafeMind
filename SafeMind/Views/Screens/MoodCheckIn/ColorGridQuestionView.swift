//
//  ColorGridQuestionView.swift
//  SafeMind
//
//  Part of the AI Mood Check-In feature.
//
//  The "What's worrying you?" card: a dark, simple layout with a 2x2 grid of
//  buttons, each colored to match its option (e.g. anxiety = teal, stress =
//  orange) so the choice reads at a glance.
//

import SwiftUI

struct ColorGridQuestionView: View {
    let question: MoodQuestion
    let selected: MoodOption?
    var onSelect: (MoodOption) -> Void
    var onSkip: () -> Void
    var onNext: () -> Void

    private let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 24)

            Text(question.text)
                .font(.title2.bold())
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer(minLength: 36)

            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(question.options) { option in
                    tile(for: option)
                }
            }
            .padding(.horizontal, 24)

            Spacer(minLength: 24)

            CheckInFooterButtons(onSkip: onSkip, onNext: onNext, nextEnabled: true, onDarkBackground: true)
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
        }
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(Color.black.opacity(0.82))
        )
        .padding(.horizontal, 12)
    }

    private func tile(for option: MoodOption) -> some View {
        let isSelected = selected?.id == option.id
        let baseColor = option.color ?? .blue
        return Button {
            onSelect(option)
        } label: {
            VStack(spacing: 8) {
                Text(option.emoji ?? "🙂")
                    .font(.system(size: 26))
                Text(option.label)
                    .font(.subheadline.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 22)
            .foregroundColor(.white)
            .background(isSelected ? baseColor : Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(isSelected ? baseColor : Color.white.opacity(0.12), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        ColorGridQuestionView(
            question: MoodQuestion.dailyCheckInQuestions[1],
            selected: MoodQuestion.dailyCheckInQuestions[1].options[2],
            onSelect: { _ in },
            onSkip: {},
            onNext: {}
        )
    }
}
