//
//  ChatBubble.swift
//  SafeMind
//
//  Part of the AI Mood Check-In feature.
//

import SwiftUI

/// A single message in the mood check-in chat — either the AI asking a
/// question or the user's selected answer.
struct MoodChatMessage: Identifiable, Equatable {
    enum Sender: Equatable { case ai, user }

    let id = UUID()
    let sender: Sender
    let text: String

    static func ai(_ text: String) -> MoodChatMessage { .init(sender: .ai, text: text) }
    static func user(_ text: String) -> MoodChatMessage { .init(sender: .user, text: text) }
}

/// Renders a `MoodChatMessage` — AI messages on the left, user selections on the right.
struct ChatBubble: View {
    let message: MoodChatMessage

    var body: some View {
        HStack {
            if message.sender == .user { Spacer(minLength: 40) }

            Text(message.text)
                .font(.subheadline)
                .foregroundColor(message.sender == .user ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(bubbleBackground)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            if message.sender == .ai { Spacer(minLength: 40) }
        }
        .transition(
            .asymmetric(
                insertion: .move(edge: message.sender == .ai ? .leading : .trailing).combined(with: .opacity),
                removal: .opacity
            )
        )
    }

    @ViewBuilder
    private var bubbleBackground: some View {
        if message.sender == .user {
            LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
        } else {
            Color(.secondarySystemBackground)
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        ChatBubble(message: .ai("How are you feeling right now?"))
        ChatBubble(message: .user("🙂 Good"))
    }
    .padding()
}
