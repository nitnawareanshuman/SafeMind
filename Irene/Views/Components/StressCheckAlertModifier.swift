//
//  StressCheckAlertModifier.swift
//  Irene
//
//  Part of the Safe Circle feature.
//
//  Attach `.stressCheckAlert()` to a view that lives inside a
//  `NavigationStack` (e.g. `HomeView`). On appear it checks
//  `MoodHistoryStore` and, at most once per day, shows a dialog offering to
//  connect the user with someone from their Safe Circle.
//

import SwiftUI

struct StressCheckAlertModifier: ViewModifier {

    @State private var showAlert = false
    @State private var navigateToSafeCircle = false

    private let historyStore = MoodHistoryStore()

    func body(content: Content) -> some View {
        content
            .onAppear(perform: evaluate)
            .alert("Feeling stressed?", isPresented: $showAlert) {
                Button("Talk to a friend") {
                    historyStore.markAlertShownToday()
                    navigateToSafeCircle = true
                }
                Button("Not now", role: .cancel) {
                    historyStore.markAlertShownToday()
                }
            } message: {
                Text("You've seemed stressed for the past few days. Reaching out to a close friend can help — want to call or message one now?")
            }
            .navigationDestination(isPresented: $navigateToSafeCircle) {
                SafeCircleContactsView()
            }
    }

    private func evaluate() {
        guard !showAlert, !navigateToSafeCircle else { return }
        guard !historyStore.hasShownAlertToday() else { return }
        if historyStore.isRecentlyStressed() {
            showAlert = true
        }
    }
}

extension View {
    /// Detects a 3-4 day stress trend and offers to open Safe Circle.
    /// Must be applied inside a `NavigationStack`.
    func stressCheckAlert() -> some View {
        modifier(StressCheckAlertModifier())
    }
}
