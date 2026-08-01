//
//  MoodRecommendation.swift
//  SafeMind
//
//  Part of the AI Mood Check-In feature.
//

import Foundation

/// The single activity SafeMind recommends after a completed mood check-in.
///
/// `.music` carries a genre so the "focus <= 3 -> Music (Focus playlist)" rule
/// can point at a specific `MusicListView(mood:)` genre rather than a generic one.
enum MoodRecommendation: Equatable {
    case breathing
    case music(genre: String)
    case cbt
    case accupressure
    case home

    var title: String {
        switch self {
        case .breathing:    return "Box Breathing"
        case .music:        return "Music"
        case .cbt:          return "CBT Thought Record"
        case .accupressure: return "Acupressure"
        case .home:         return "Home"
        }
    }

    /// The line shown on the recommendation screen, e.g. "I think a short breathing exercise could help you feel calmer."
    var message: String {
        switch self {
        case .breathing:
            return "I think a short breathing exercise could help you feel calmer."
        case .music(let genre) where genre == "Focus":
            return "A focus playlist could help clear your head."
        case .music(let genre) where genre == "Sleep":
            return "You sound worn out — some rest music could help you recharge."
        case .music:
            return "Some calming music might help you recharge."
        case .cbt:
            return "Working through a quick thought record could help untangle things."
        case .accupressure:
            return "A few minutes of acupressure could ease that tension."
        case .home:
            return "You're doing okay — let's head to your dashboard."
        }
    }

    var icon: String {
        switch self {
        case .breathing:    return "wind"
        case .music:        return "headphones"
        case .cbt:          return "brain.head.profile"
        case .accupressure: return "hand.point.up"
        case .home:         return "house.fill"
        }
    }
}

// MARK: - Codable

// Manual Codable so the associated `genre` value survives round-tripping
// through `UserDefaults` in `MoodCheckInStore`.
extension MoodRecommendation: Codable {

    private enum CodingKeys: String, CodingKey { case kind, genre }

    private enum Kind: String, Codable {
        case breathing, music, cbt, accupressure, home
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch try container.decode(Kind.self, forKey: .kind) {
        case .breathing:    self = .breathing
        case .cbt:          self = .cbt
        case .accupressure: self = .accupressure
        case .home:         self = .home
        case .music:
            let genre = try container.decodeIfPresent(String.self, forKey: .genre) ?? "Calm"
            self = .music(genre: genre)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .breathing:    try container.encode(Kind.breathing, forKey: .kind)
        case .cbt:          try container.encode(Kind.cbt, forKey: .kind)
        case .accupressure: try container.encode(Kind.accupressure, forKey: .kind)
        case .home:         try container.encode(Kind.home, forKey: .kind)
        case .music(let genre):
            try container.encode(Kind.music, forKey: .kind)
            try container.encode(genre, forKey: .genre)
        }
    }
}
