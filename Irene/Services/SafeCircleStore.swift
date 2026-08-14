//
//  SafeCircleStore.swift
//  Irene
//
//  Part of the Safe Circle feature.
//
//  UserDefaults-only for now, mirroring `MoodCheckInStore`'s pattern. Future
//  extensibility: this is the seam to swap in a Supabase-backed store (e.g. a
//  `safe_circle_contacts` table keyed by uid) so the circle syncs across
//  devices — `SafeCircleViewModel` only ever talks to this struct's methods.
//

import Foundation

struct SafeCircleStore {

    /// Product requirement: 1-3 close friends, no more.
    let maxContacts = 3

    private let defaults: UserDefaults
    private let contactsKey = "safeCircle.contacts"
    private let onboardingSeenKey = "safeCircle.onboardingSeen"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func contacts() -> [SafeCircleContact] {
        guard let data = defaults.data(forKey: contactsKey),
              let decoded = try? JSONDecoder().decode([SafeCircleContact].self, from: data) else {
            return []
        }
        return decoded
    }

    func save(_ contacts: [SafeCircleContact]) {
        let capped = Array(contacts.prefix(maxContacts))
        if let data = try? JSONEncoder().encode(capped) {
            defaults.set(data, forKey: contactsKey)
        }
    }

    /// Whether the post-sign-up "add a close friend" screen has already been
    /// shown (and skipped or completed) once, so it never appears again.
    func hasSeenOnboarding() -> Bool {
        defaults.bool(forKey: onboardingSeenKey)
    }

    func markOnboardingSeen() {
        defaults.set(true, forKey: onboardingSeenKey)
    }
}
