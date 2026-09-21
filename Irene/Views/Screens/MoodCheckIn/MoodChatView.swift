//
//  MoodChatView.swift
//  Irene
//
//  Part of the AI Mood Check-In feature.
//
//  Note: the on-screen type is `MoodCheckInChatView` (not `MoodChatView`) —
//  `MoodChatView` was already taken by the earlier on-device LLM experiment,
//  which now lives under Views/AITesting as `LLMMoodChatView`.
//

import SwiftUI

/// The full AI Mood Check-In experience: one full-screen question "card" at a
/// time (layout picked per-question via `MoodQuestion.style`), a segmented
/// progress line at the top, an "Analyzing…" beat, then a single recommended
/// activity.
///
/// - When presented as the once-a-day gate before `HomeView` (see `ContentView`),
///   pass `onComplete` so the caller can dismiss into Home once the flow ends.
/// - When pushed from `HomeView`'s greeting card for a manual re-check-in,
///   leave `onComplete` nil — this view then behaves like any other pushed screen.
struct MoodCheckInChatView: View {

    @StateObject private var vm = MoodCheckInViewModel()
    @State private var navigateToActivity = false

    var onComplete: (() -> Void)? = nil

    var body: some View {
        ZStack {
            BlurBackground()

            if let assessment = vm.assessment, let recommendation = vm.recommendation {
                RecommendationView(
                    assessment: assessment,
                    recommendation: recommendation,
                    onStartActivity: {
                        onComplete?()
                        navigateToActivity = true
                    }
                )
                .transition(.opacity)
            } else if vm.needsSelection {
                SelectionRequiredView(onBackToCheckIn: { vm.reset() })
                    .transition(.opacity)
            } else if vm.isAnalyzing {
                AnalyzingView()
                    .transition(.opacity)
            } else if let question = vm.currentQuestion {
                VStack(spacing: 0) {
                    MoodTopProgressBar(
                        totalSteps: vm.totalQuestions,
                        currentStep: vm.questionIndex
                    )
                    card(for: question)
                        .id(question.id)
                        .transition(cardTransition)
                }
            }
        }
        .navigationTitle("Mood Check-In")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { vm.start() }
        .navigationDestination(isPresented: $navigateToActivity) {
            if let recommendation = vm.recommendation {
                destinationView(for: recommendation)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: vm.assessment)
        .animation(.easeInOut(duration: 0.3), value: vm.needsSelection)
        .animation(.easeInOut(duration: 0.3), value: vm.isAnalyzing)
        .animation(.easeInOut(duration: 0.3), value: vm.questionIndex)
    }

    /// "Next" slides the new card in from the right (the natural forward
    /// direction); "Previous" mirrors that and slides the new card in from
    /// the left, so going back visibly feels like going back instead of
    /// reusing the forward animation.
    private var cardTransition: AnyTransition {
        switch vm.navigationDirection {
        case .forward:
            return .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            )
        case .backward:
            return .asymmetric(
                insertion: .move(edge: .leading).combined(with: .opacity),
                removal: .move(edge: .trailing).combined(with: .opacity)
            )
        }
    }

    // MARK: - Card routing

    @ViewBuilder
    private func card(for question: MoodQuestion) -> some View {
        switch question.style {
        case .emojiFace:
            EmojiFaceQuestionView(
                question: question,
                selected: vm.pendingOption,
                onSelect: { vm.select($0) },
                onPrevious: { vm.goBack() },
                showPrevious: vm.questionIndex > 0,
                onNext: { vm.advance() }
            )
        case .colorGrid:
            ColorGridQuestionView(
                question: question,
                selected: vm.pendingOption,
                onSelect: { vm.select($0) },
                onPrevious: { vm.goBack() },
                showPrevious: vm.questionIndex > 0,
                onNext: { vm.advance() }
            )
        case .verticalSlider:
            VerticalSliderQuestionView(
                question: question,
                selected: vm.pendingOption,
                onSelect: { vm.select($0) },
                onPrevious: { vm.goBack() },
                showPrevious: vm.questionIndex > 0,
                onNext: { vm.advance() }
            )
        case .simpleList:
            SimpleListQuestionView(
                question: question,
                selected: vm.pendingOption,
                onSelect: { vm.select($0) },
                onPrevious: { vm.goBack() },
                showPrevious: vm.questionIndex > 0,
                onNext: { vm.advance() }
            )
        }
    }

    // MARK: - Navigation

    @ViewBuilder
    private func destinationView(for recommendation: MoodRecommendation) -> some View {
        switch recommendation {
        case .breathing:
            BreathingView()
        case .accupressure:
            AccupressureView()
        case .journaling:
            JournalView()
        case .music(let genre):
            MusicListView(mood: genre)
        case .home:
            HomeView()
        }
    }

}

/// Shown instead of the recommendation when the user reached the end of the
/// check-in without picking an option on every question.
private struct SelectionRequiredView: View {
    var onBackToCheckIn: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 56, weight: .semibold))
                .foregroundColor(.primary)

            Text("Please select something")
                .font(.title2.weight(.bold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)

            Text("Looks like one or more questions were left unanswered. Go back and pick an option for each one so we can put together your check-in.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            Button(action: onBackToCheckIn) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.left")
                    Text("Back to Mood Check-In")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.primary)
                .padding(.horizontal, 26)
                .padding(.vertical, 14)
                .background(Color(.secondarySystemBackground))
                .clipShape(Capsule())
            }
            .padding(.bottom, 40)
        }
    }
}

#Preview {
    NavigationStack {
        MoodCheckInChatView()
    }
}
