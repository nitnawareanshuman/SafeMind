//
//  MoodAssessmentViewModel.swift
//  SafeMind
//
//  Created by Anshuman Nitnaware on 21/07/26.
//


import SwiftUI
import Combine

@MainActor
final class MoodAssessmentViewModel: ObservableObject {

    @Published var currentQuestion: MoodQuestion?
    @Published var history: [MoodQA] = []
    @Published var isLoading = false
    @Published var finalResult: MoodAnalysis?
    @Published var errorMessage: String?
    @Published var availability: ModelAvailability = .ready

    private let engine: MoodAIEngineProtocol
    private let questionCount = 2 // 2-3 Qs before analysis

    init(engine: MoodAIEngineProtocol = MoodAIEngine()) {
        self.engine = engine
        self.availability = engine.checkAvailability()
    }

    func start() {
        availability = engine.checkAvailability()
        guard availability == .ready else { return }
        Task { await loadNextQuestion() }
    }

    func select(option: String) {
        guard let q = currentQuestion else { return }
        history.append(MoodQA(question: q.question, answer: option))
        currentQuestion = nil

        Task {
            if history.count >= questionCount {
                await runAnalysis()
            } else {
                await loadNextQuestion()
            }
        }
    }

    private func loadNextQuestion() async {
        isLoading = true
        errorMessage = nil
        do {
            currentQuestion = try await engine.nextQuestion(history: history)
        } catch {
            errorMessage = "Couldn't load next question. Try again."
        }
        isLoading = false
    }

    private func runAnalysis() async {
        isLoading = true
        do {
            finalResult = try await engine.analyze(history: history)
        } catch {
            errorMessage = "Couldn't analyze mood. Try again."
        }
        isLoading = false
    }

    func reset() {
        currentQuestion = nil
        history = []
        finalResult = nil
        errorMessage = nil
        start()
    }
}
