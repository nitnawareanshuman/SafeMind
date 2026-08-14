//
//  JournalEntry.swift
//  Irene
//
//  Part of the Journaling feature.
//

import Foundation
import SwiftUI

/// The mood a user attaches to a journal entry. Kept separate from
/// `MoodOption` (used by the AI Mood Check-In) since journaling is a
/// lightweight, user-driven log rather than a computed assessment.
enum JournalMood: String, Codable, CaseIterable, Identifiable {
    case great, good, okay, low, awful

    var id: String { rawValue }

    var label: String {
        switch self {
        case .great: return "Great"
        case .good:  return "Good"
        case .okay:  return "Okay"
        case .low:   return "Low"
        case .awful: return "Awful"
        }
    }

    var emoji: String {
        switch self {
        case .great: return "😄"
        case .good:  return "🙂"
        case .okay:  return "😐"
        case .low:   return "😔"
        case .awful: return "😣"
        }
    }

    var color: Color {
        switch self {
        case .great: return Color(hex: "#7FE0C9")
        case .good:  return Color(hex: "#A6D96A")
        case .okay:  return Color(hex: "#F3D250")
        case .low:   return Color(hex: "#8FB8E8")
        case .awful: return Color(hex: "#E88787")
        }
    }

    /// 1–5 scale (higher = better mood) used to plot the mood trend graph.
    var score: Int {
        switch self {
        case .great: return 5
        case .good:  return 4
        case .okay:  return 3
        case .low:   return 2
        case .awful: return 1
        }
    }
}

/// A single user-written journal entry.
struct JournalEntry: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var date: Date
    var mood: JournalMood
    var title: String
    var description: String

    init(id: UUID = UUID(), date: Date = Date(), mood: JournalMood, title: String, description: String) {
        self.id = id
        self.date = date
        self.mood = mood
        self.title = title
        self.description = description
    }
}
