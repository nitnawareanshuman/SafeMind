//
//  SafeCircleContact.swift
//  Irene
//
//  Part of the Safe Circle feature.
//
//  A lightweight, locally-stored reference to a contact the user picked from
//  the system Contacts app. We intentionally only keep a name + phone number
//  (not a `CNContact` or its identifier) so this stays simple to persist and
//  doesn't require re-resolving a contact identifier against the Contacts
//  database every time it's shown.
//

import Foundation

struct SafeCircleContact: Codable, Identifiable, Equatable {
    let id: String
    var name: String
    var phoneNumber: String

    init(id: String = UUID().uuidString, name: String, phoneNumber: String) {
        self.id = id
        self.name = name
        self.phoneNumber = phoneNumber
    }

    /// Digits/`+`-only version of the number, safe to drop straight into a
    /// `tel://` or `sms:` URL.
    var dialableNumber: String {
        phoneNumber.filter { $0.isNumber || $0 == "+" }
    }
}
