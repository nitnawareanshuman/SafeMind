//
//  EmojiFaceQuestionView.swift
//  SafeMind
//
//  Part of the AI Mood Check-In feature.
//
//  The "How do you feel today?" card: a big color-changing circle with a
//  large emoji in the middle, a horizontally scrolling pill row of options
//  underneath, the question title, and Skip / Next controls.
//
//  Emoji are placeholders — swap `option.emoji` for real emoji illustrations
//  whenever those are ready; nothing else about this view needs to change.
//

import SwiftUI

struct EmojiFaceQuestionView: View {
    let question: MoodQuestion
    let selected: MoodOption?
    var onSelect: (MoodOption) -> Void
    var onSkip: () -> Void
    var onNext: () -> Void

    private var active: MoodOption { selected ?? question.options[0] }

    var body: some View {
        VStack(spacing: 0) {
            // Big face card
            ZStack {

                Image(active.imageName ?? "happy_face")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 350, height: 350)
                    .clipShape(RoundedRectangle(cornerRadius: 32))
                    .animation(.easeInOut(duration: 0.25), value: active.id)
            }
            .frame(height: 340)
            .padding(.horizontal, 20)
            .padding(.top, 16)

            // Horizontally scrolling pill selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(question.options) { option in
                        pill(for: option)
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.top, 22)

            Text("How do you\nfeel today?")
                .font(.system(size: 38, weight: .bold))
                .multilineTextAlignment(.center)
                .lineSpacing(-3)
                .foregroundColor(.primary)
                .padding(.top, 68)

            Spacer(minLength: 12)

            CheckInFooterButtons(onSkip: onSkip, onNext: onNext, nextEnabled: true)
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
        }
    }

    private func pill(for option: MoodOption) -> some View {
        let isSelected = selected?.id == option.id
        return Button {
            onSelect(option)
        } label: {
            Text(option.label)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(isSelected ? (option.color ?? .pink) : Color(.secondarySystemBackground))
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

/// Shared Skip / Next footer used by every redesigned check-in card.
struct CheckInFooterButtons: View {
    var onSkip: () -> Void
    var onNext: () -> Void
    var nextEnabled: Bool
    /// Pass `true` when this footer sits on a dark card (e.g. the worry
    /// grid) so "Skip" stays legible; the white Next pill works on both.
    var onDarkBackground: Bool = false

    var body: some View {
        HStack {
            Button("Skip", action: onSkip)
                .font(.subheadline.weight(.medium))
                .foregroundColor(onDarkBackground ? .white.opacity(0.5) : .black.opacity(0.45))

            Spacer()

            Button(action: onNext) {
                HStack(spacing: 6) {
                    Text("Next")
                    Image(systemName: "chevron.right")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.black)
                .padding(.horizontal, 26)
                .padding(.vertical, 14)
                .background(Color.white)
                .clipShape(Capsule())
                .opacity(nextEnabled ? 1 : 0.5)
            }
            .disabled(!nextEnabled)
        }
    }
}

#Preview {
    EmojiFaceQuestionView(
        question: MoodQuestion.dailyCheckInQuestions[0],
        selected: MoodQuestion.dailyCheckInQuestions[0].options[1],
        onSelect: { _ in },
        onSkip: {},
        onNext: {}
    )
}
