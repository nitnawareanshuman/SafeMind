//
//  JournalDetailView.swift
//  Irene
//
//  Part of the Journaling feature.
//
//  Read-only detail screen for a single saved journal entry — opened when
//  the user taps an entry card in `JournalView`. Shows the mood, date, title
//  and full description, with a delete action in the toolbar.
//

import SwiftUI

struct JournalDetailView: View {

    let entry: JournalEntry
    var onDelete: (JournalEntry) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirm = false

    var body: some View {
        ZStack {
            BlurBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {

                    // Mood + date header
                    HStack(spacing: 14) {
                        Text(entry.mood.emoji)
                            .font(.system(size: 40))
                            .frame(width: 64, height: 64)
                            .background(entry.mood.color.opacity(0.3))
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.mood.label)
                                .font(.headline)
                            Text(entry.date, format: .dateTime.day().month(.wide).year().hour().minute())
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)

                    // Title
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Title")
                            .font(.headline)
                        Text(entry.title.isEmpty ? "Untitled" : entry.title)
                            .font(.title3.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)

                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("What you wrote")
                            .font(.headline)
                        Text(entry.description.isEmpty ? "No additional notes." : entry.description)
                            .font(.body)
                            .foregroundColor(entry.description.isEmpty ? .secondary : .primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                }
                .padding()
            }
        }
        .navigationTitle("Journal Entry")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
        .alert("Delete this entry?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                onDelete(entry)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

#Preview {
    NavigationStack {
        JournalDetailView(
            entry: JournalEntry(
                mood: .good,
                title: "A calmer day",
                description: "Went for a walk in the evening and felt a lot lighter afterward."
            ),
            onDelete: { _ in }
        )
    }
}
