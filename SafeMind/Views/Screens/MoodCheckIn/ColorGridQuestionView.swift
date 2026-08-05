//
//  ColorGridQuestionView.swift
//  SafeMind
//

import SwiftUI

struct ColorGridQuestionView: View {

    let question: MoodQuestion
    let selected: MoodOption?

    var onSelect: (MoodOption) -> Void
    var onSkip: () -> Void
    var onNext: () -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 18),
        GridItem(.flexible(), spacing: 18)
    ]

    var body: some View {

        ZStack {

            VStack(spacing: 0) {

                Spacer()
                    .frame(height: 30)

                Text(question.text)
                    .font(.system(size: 32, weight: .bold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
                    .padding(.top, 25)
                    .padding(.horizontal, 28)

                Spacer(minLength: 30)

                LazyVGrid(columns: columns, spacing: 18) {
                    ForEach(question.options) { option in
                        tile(for: option)
                    }
                }
                .padding(.horizontal, 20)

                Spacer()

                CheckInFooterButtons(
                    onSkip: onSkip,
                    onNext: onNext,
                    nextEnabled: true
                )
                .padding(.horizontal,20)
                .padding(.bottom,8)

            }
        }
    }

    private func tile(for option: MoodOption) -> some View {

        let selected = selected?.id == option.id
        let color = option.color ?? .blue

        return Button {

            onSelect(option)

        } label: {

            VStack(spacing: 18) {

                Spacer()

                if let image = option.imageName {

                    Image(image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 84,height: 84)

                }

                Text(option.label)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)

                Spacer()

            }
            .frame(maxWidth: .infinity)
            .frame(height: 180)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(
                        selected
                        ? color
                        : Color.white.opacity(0.28)
                    )
            )

            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .stroke(
                        Color.white.opacity(selected ? 0 : 0.15),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: selected ?
                color.opacity(0.45) :
                .clear,
                radius: 18
            )
            .scaleEffect(selected ? 1.05 : 1)
            .animation(.spring(response: 0.35,dampingFraction: 0.75), value: selected)

        }
        .buttonStyle(.plain)

    }
}

#Preview {

    ColorGridQuestionView(
        question: MoodQuestion.dailyCheckInQuestions[1],
        selected: MoodQuestion.dailyCheckInQuestions[1].options[2],
        onSelect: { _ in },
        onSkip: {},
        onNext: {}
    )

}
