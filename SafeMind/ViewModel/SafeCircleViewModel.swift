//
//  SafeCircleViewModel.swift
//  SafeMind
//
//  Part of the Safe Circle feature.
//

import SwiftUI
import Combine

@MainActor
final class SafeCircleViewModel: ObservableObject {

    @Published private(set) var contacts: [SafeCircleContact]
    @Published var showContactPicker = false
    @Published var errorMessage: String?

    private let store: SafeCircleStore

    var maxContacts: Int { store.maxContacts }
    var canAddMore: Bool { contacts.count < store.maxContacts }

    init(store: SafeCircleStore = SafeCircleStore()) {
        self.store = store
        self.contacts = store.contacts()
    }

    func addContact(_ contact: SafeCircleContact) {
        errorMessage = nil

        guard canAddMore else {
            errorMessage = "You can add up to \(store.maxContacts) close friends."
            return
        }
        guard !contacts.contains(where: { $0.dialableNumber == contact.dialableNumber }) else {
            errorMessage = "\(contact.name) is already in your Safe Circle."
            return
        }

        contacts.append(contact)
        store.save(contacts)
    }

    func removeContact(_ contact: SafeCircleContact) {
        contacts.removeAll { $0.id == contact.id }
        store.save(contacts)
    }

    func delete(at offsets: IndexSet) {
        contacts.remove(atOffsets: offsets)
        store.save(contacts)
    }

    func markOnboardingSeen() {
        store.markOnboardingSeen()
    }

    // MARK: - Static helpers (for use outside a view model instance, e.g. ContentView's routing)

    static func hasSeenOnboarding(store: SafeCircleStore = SafeCircleStore()) -> Bool {
        store.hasSeenOnboarding()
    }
}
