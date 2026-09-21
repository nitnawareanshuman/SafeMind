//
//  EmojiFaceQuestionView.swift
//  Irene
//
//  Part of the AI Mood Check-In feature.
//
//  The "How do you feel today?" card: a big color-changing circle with a
//  large emoji in the middle, a horizontally scrolling pill row of options
//  underneath, the question title, and Previous / Next controls.
//
//  Emoji are placeholders — swap `option.emoji` for real emoji illustrations
//  whenever those are ready; nothing else about this view needs to change.
//

import SwiftUI

struct EmojiFaceQuestionView: View {
    @Environment(\.colorScheme) private var colorScheme
    let question: MoodQuestion
    let selected: MoodOption?
    var onSelect: (MoodOption) -> Void
    var onPrevious: () -> Void
    var showPrevious: Bool = false
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

            CheckInFooterButtons(onPrevious: onPrevious, onNext: onNext, nextEnabled: true, showPrevious: showPrevious)
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
                .background(isSelected ? (option.color ?? .pink).opacity(colorScheme == .dark ? 0.25 : 0.4) : Color(.secondarySystemBackground))
                .foregroundColor(.primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

/// Shared Previous / Next footer used by every redesigned check-in card.
/// There's no "Skip" anymore — every question just records whatever is
/// selected (possibly nothing) when "Next" is tapped; users can always
/// step back with "Previous" to fill in something they left blank.
struct CheckInFooterButtons: View {
    var onPrevious: () -> Void
    var onNext: () -> Void
    var nextEnabled: Bool
    /// Hidden entirely on the very first question — there's nothing behind it.
    var showPrevious: Bool = false
    /// Pass `true` when this footer sits on a dark card (e.g. the worry
    /// grid) so the Previous control stays legible. Next uses an adaptive surface.
    var onDarkBackground: Bool = false

    var body: some View {
        HStack(spacing: 14) {
            if showPrevious {
                Button(action: onPrevious) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                        Text("Previous")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(onDarkBackground ? .white : .primary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(
                        Capsule()
                            .fill(onDarkBackground ? Color.white.opacity(0.14) : Color(.secondarySystemBackground))
                    )
                    .overlay(
                        Capsule()
                            .stroke(onDarkBackground ? Color.white.opacity(0.18) : Color.primary.opacity(0.08), lineWidth: 1)
                    )
                }
                .transition(.scale.combined(with: .opacity))
            }

            Spacer()

            Button(action: onNext) {
                HStack(spacing: 6) {
                    Text("Next")
                    Image(systemName: "chevron.right")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.primary)
                .padding(.horizontal, 26)
                .padding(.vertical, 14)
                .background(Color(.secondarySystemBackground))
                .clipShape(Capsule())
                .opacity(nextEnabled ? 1 : 0.5)
            }
            .disabled(!nextEnabled)
        }
        .animation(.easeInOut(duration: 0.2), value: showPrevious)
    }
}

#Preview {
    EmojiFaceQuestionView(
        question: MoodQuestion.dailyCheckInQuestions[0],
        selected: MoodQuestion.dailyCheckInQuestions[0].options[1],
        onSelect: { _ in },
        onPrevious: {},
        showPrevious: true,
        onNext: {}
    )
}
