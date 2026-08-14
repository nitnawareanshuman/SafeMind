//
//  ContactPickerView.swift
//  Irene
//
//  Part of the Safe Circle feature.
//
//  Thin wrapper around `CNContactPickerViewController` — Apple's built-in
//  Contacts UI. It runs out-of-process, so no `NSContactsUsageDescription` /
//  Contacts permission prompt is needed for this picker flow.
//
//  `displayedPropertyKeys = [CNContactPhoneNumbersKey]` makes the picker jump
//  straight to phone-number selection: tapping a contact with one number
//  picks it immediately, tapping a contact with several numbers shows just
//  those numbers to choose from.
//

import SwiftUI
import ContactsUI
import Contacts

struct ContactPickerView: UIViewControllerRepresentable {

    var onPick: (SafeCircleContact) -> Void
    var onCancel: (() -> Void)? = nil

    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        picker.predicateForEnablingContact = NSPredicate(format: "phoneNumbers.@count > 0")
        picker.displayedPropertyKeys = [CNContactPhoneNumbersKey]
        return picker
    }

    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick, onCancel: onCancel)
    }

    final class Coordinator: NSObject, CNContactPickerDelegate {
        private let onPick: (SafeCircleContact) -> Void
        private let onCancel: (() -> Void)?

        init(onPick: @escaping (SafeCircleContact) -> Void, onCancel: (() -> Void)?) {
            self.onPick = onPick
            self.onCancel = onCancel
        }

        /// Called when the picker's `displayedPropertyKeys` narrows selection
        /// down to a single phone-number property (the normal path here).
        func contactPicker(_ picker: CNContactPickerViewController, didSelect contactProperty: CNContactProperty) {
            guard let phoneNumber = contactProperty.value as? CNPhoneNumber else { return }
            let name = CNContactFormatter.string(from: contactProperty.contact, style: .fullName)
                ?? "Unnamed Contact"
            onPick(SafeCircleContact(name: name, phoneNumber: phoneNumber.stringValue))
        }

        /// Fallback in case a full contact (rather than a single property)
        /// gets selected — use its first phone number.
        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            guard let phoneNumber = contact.phoneNumbers.first?.value else { return }
            let name = CNContactFormatter.string(from: contact, style: .fullName) ?? "Unnamed Contact"
            onPick(SafeCircleContact(name: name, phoneNumber: phoneNumber.stringValue))
        }

        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
            onCancel?()
        }
    }
}
