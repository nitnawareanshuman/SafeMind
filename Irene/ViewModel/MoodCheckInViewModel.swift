//
//  MoodCheckInViewModel.swift
//  Irene
//
//  Part of the AI Mood Check-In feature.
//

import SwiftUI
import Combine

/// Drives the redesigned AI Mood Check-In flow: one full-screen question
/// "card" at a time (the exact card layout comes from `MoodQuestion.style`),
/// with an explicit tap-to-select + Previous/Next per card rather than an
/// auto-advancing chat. Once every question has an actual selection, it asks
/// `MoodAssessmentService` + `RecommendationEngine` to turn the answers into a
/// `MoodAssessment` and a single recommended activity. If the user reaches
/// the end without picking something on every question, `needsSelection`
/// flips on instead so the View can prompt them to go back and finish up.
///
/// Future extensibility: swap `questions` for a dynamically generated set
/// (e.g. LLM-driven, or personalized from history) without touching the View —
/// it only ever talks to `currentQuestion` / `select(_:)` / `advance()` / `goBack()`.
@MainActor
final class MoodCheckInViewModel: ObservableObject {

    /// Which way the card transition should animate — set by `advance()`
    /// (forward) and `goBack()` (backward) so the View can slide the new
    /// card in from the matching edge instead of always sliding in from
    /// the right.
    enum NavigationDirection {
        case forward
        case backward
    }

    // MARK: - Published UI state

    @Published private(set) var currentQuestion: MoodQuestion?
    /// The option the user has tapped for the question currently on screen,
    /// but not yet confirmed with "Next". Cleared on every question change.
    /// `nil` means nothing has been picked for this question yet.
    @Published var pendingOption: MoodOption?
    @Published private(set) var isAnalyzing = false
    @Published private(set) var assessment: MoodAssessment?
    @Published private(set) var recommendation: MoodRecommendation?
    @Published private(set) var questionIndex = 0 // how many questions have been stepped past so far
    @Published private(set) var navigationDirection: NavigationDirection = .forward
    /// True once the user has clicked through every question but left at
    /// least one without an actual selection. The View shows a "Please
    /// select something" screen with a way back into the flow instead of
    /// the recommendation.
    @Published private(set) var needsSelection = false

    let totalQuestions: Int

    // MARK: - Dependencies

    private let questions: [MoodQuestion]
    private let assessmentService: MoodAssessmentService
    private let recommendationEngine: RecommendationEngine
    private let store: MoodCheckInStore
    /// Part of the Safe Circle feature — records today's stress score so a
    /// multi-day stress trend can be detected later (see `HomeView`'s
    /// `.stressCheckAlert()`).
    private let historyStore: MoodHistoryStore

    /// One slot per question, in order. `nil` until the user actually taps
    /// an option on that question and hits "Next" — there is no silent
    /// neutral default, so going back always shows exactly what (if
    /// anything) was picked.
    private var answers: [MoodOption?] = []

    init(
        questions: [MoodQuestion] = MoodQuestion.dailyCheckInQuestions,
        assessmentService: MoodAssessmentService = MoodAssessmentService(),
        recommendationEngine: RecommendationEngine = RecommendationEngine(),
        store: MoodCheckInStore = MoodCheckInStore(),
        historyStore: MoodHistoryStore = MoodHistoryStore()
    ) {
        self.questions = questions
        self.totalQuestions = questions.count
        self.assessmentService = assessmentService
        self.recommendationEngine = recommendationEngine
        self.store = store
        self.historyStore = historyStore
    }

    // MARK: - Flow

    /// Shows the first card. Safe to call multiple times (e.g. `onAppear`
    /// firing again) — it no-ops once the flow has already started.
    func start() {
        guard currentQuestion == nil, assessment == nil, questionIndex == 0, !needsSelection else { return }
        currentQuestion = questions.first
    }

    /// Restarts the whole flow from scratch (used by "Start over" and by
    /// the "Please select something" screen's "Back to Mood Check-In").
    func reset() {
        navigationDirection = .forward
        currentQuestion = questions.first
        pendingOption = nil
        isAnalyzing = false
        assessment = nil
        recommendation = nil
        needsSelection = false
        questionIndex = 0
        answers = []
    }

    /// Taps an option on the current card — just highlights it, doesn't advance.
    func select(_ option: MoodOption) {
        pendingOption = option
    }

    /// "Next" — commits whatever's selected (or nil, if nothing was
    /// tapped — no more silently substituting a neutral default) and
    /// moves to the following card.
    func advance() {
        guard let question = currentQuestion else { return }
        navigationDirection = .forward
        recordAnswer(question: question, option: pendingOption)
    }

    private func recordAnswer(question: MoodQuestion, option: MoodOption?) {
        if answers.count > questionIndex {
            answers[questionIndex] = option
        } else {
            answers.append(option)
        }
        pendingOption = nil
        questionIndex += 1
        askNextQuestion()
    }

    private func askNextQuestion() {
        guard questionIndex < questions.count else {
            currentQuestion = nil
            if answers.count < questions.count || answers.contains(where: { $0 == nil }) {
                // Something was left unanswered — don't compute a
                // recommendation from incomplete data.
                needsSelection = true
            } else {
                Task { await finish() }
            }
            return
        }
        currentQuestion = questions[questionIndex]
    }

    private func finish() async {
        isAnalyzing = true

        // "Analyzing your responses…" gets a couple of seconds to breathe before revealing the result.
        try? await Task.sleep(nanoseconds: 1_600_000_000)

        let answeredPairs: [(question: MoodQuestion, option: MoodOption)] = zip(questions, answers).compactMap { question, option in
            guard let option else { return nil }
            return (question, option)
        }

        let result = assessmentService.computeAssessment(from: answeredPairs)
        let rec = recommendationEngine.recommend(for: result)

        assessment = result
        recommendation = rec
        isAnalyzing = false

        store.saveTodaysResult(assessment: result, recommendation: rec)
        historyStore.recordToday(stress: result.stress)
        ActivityStore.shared.record(type: "moodCheckIn")
    }

    /// "Previous" — steps back to the question before the one on screen,
    /// restoring exactly what (if anything) was selected for it. Can only
    /// go back as far as the very first question (`questionIndex == 0` is
    /// the floor).
    func goBack() {
        guard questionIndex > 0 else { return }
        navigationDirection = .backward
        needsSelection = false

        // Move back one question
        questionIndex -= 1

        // Show the previous question, restoring exactly what was (or
        // wasn't) picked for it — never a substituted default.
        currentQuestion = questions[questionIndex]
        pendingOption = answers.indices.contains(questionIndex) ? answers[questionIndex] : nil
    }

    // MARK: - Daily gate

    /// Whether today's check-in was already completed (checked once, up front,
    /// by whoever decides whether to present this flow at all — see `ContentView`).
    static func hasCompletedToday(store: MoodCheckInStore = MoodCheckInStore()) -> Bool {
        store.hasCompletedToday()
    }
}
