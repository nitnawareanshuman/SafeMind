//
//  MoodChatView.swift
//  SafeMind
//
//  Created by Anshuman Nitnaware on 21/07/26.
//


import SwiftUI

struct MoodChatView: View {
    // TESTING: swap to MoodAssessmentViewModel() (real engine) once mock flow looks right
    @StateObject private var vm = MoodAssessmentViewModel(engine: MockMoodAIEngine())
    @State private var navigateTo: RecommendedDestination?

    var body: some View {
        ZStack {
            BlurBackground()

            VStack(spacing: 24) {
                progressDots

                switch vm.availability {
                case .notEnabled:
                    unavailableState(text: "Turn on Apple Intelligence in Settings to use mood check-in.")
                case .notEligible:
                    unavailableState(text: "This device doesn't support on-device AI mood check-in.")
                case .downloading:
                    unavailableState(text: "AI model is still downloading. Try again shortly.")
                case .ready:
                    readyContent
                }
            }
            .padding()
        }
        .onAppear { vm.start() }
        .navigationDestination(item: $navigateTo) { dest in
            destinationView(for: dest)
        }
    }

    @ViewBuilder
    private var readyContent: some View {
        if let result = vm.finalResult {
            resultCard(result)
        } else if vm.isLoading {
            ProgressView().tint(.white)
        } else if let q = vm.currentQuestion {
            questionCard(q)
        } else if let err = vm.errorMessage {
            unavailableState(text: err)
        }
    }

    private func questionCard(_ q: MoodQuestion) -> some View {
        VStack(spacing: 20) {
            Text(q.question)
                .font(.title3.bold())
                .multilineTextAlignment(.center)
                .foregroundColor(.white)

            VStack(spacing: 12) {
                ForEach(q.options, id: \.self) { option in
                    Button {
                        vm.select(option: option)
                    } label: {
                        Text(option)
                            .font(.subheadline.weight(.medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(.white.opacity(0.15))
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
            }
        }
        .padding(24)
        .background(.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private func resultCard(_ result: MoodAnalysis) -> some View {
        VStack(spacing: 16) {
            Text("Feeling \(result.mood.rawValue)")
                .font(.title2.bold())
                .foregroundColor(.white)
            Text(result.reasoning)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.white.opacity(0.85))
                .padding(.horizontal)

            Button {
                navigateTo = result.destination
            } label: {
                Text("Take me there")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(.white)
                    .foregroundColor(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.top, 8)

            Button("Start over") { vm.reset() }
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(24)
    }

    private func unavailableState(text: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.largeTitle)
                .foregroundColor(.white.opacity(0.7))
            Text(text)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }

    private var progressDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<2, id: \.self) { i in
                Circle()
                    .fill(i < vm.history.count ? Color.white : Color.white.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
    }

    @ViewBuilder
    private func destinationView(for dest: RecommendedDestination) -> some View {
        switch dest {
        case .boxBreathing:
            BreathingView()
        case .breathing478:
            BreathingView()
        case .acupressure:
            AccupressureView()
        case .musicCalm:
            GenreTrackListView(genre: genre(named: "Calm"))
        case .musicFocus:
            GenreTrackListView(genre: genre(named: "Focus"))
        case .musicSleep:
            GenreTrackListView(genre: genre(named: "Sleep"))
        case .musicEnergy:
            GenreTrackListView(genre: genre(named: "Energy"))
        }
    }

    private func genre(named name: String) -> MusicGenre {
        allGenres.first(where: { $0.name == name }) ?? allGenres[0]
    }
}

extension RecommendedDestination: Identifiable {
    var id: String { rawValue }
}
