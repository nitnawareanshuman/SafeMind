//
//  CreateJournalView.swift
//  SafeMind
//
//  Part of the Journaling feature.
//
//  Date + mood + title + description ("Express your thoughts") entry form.
//  On save, hands the new entry back to the caller (`JournalView`) and pops
//  back to the journal list.
//

import SwiftUI

struct CreateJournalView: View {

    @Environment(\.dismiss) private var dismiss

    /// (mood, title, description, date)
    var onSave: (JournalMood, String, String, Date) -> Void

    @State private var date = Date()
    @State private var selectedMood: JournalMood? = nil
    @State private var title = ""
    @State private var description = ""

    private var canSave: Bool {
        selectedMood != nil && !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ZStack {
            BlurBackground()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {

                        // Date
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Date")
                                .font(.headline)
                            DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(.compact)
                                .labelsHidden()
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)

                        // Mood
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Mood")
                                .font(.headline)

                            HStack(spacing: 12) {
                                ForEach(JournalMood.allCases) { mood in
                                    moodButton(mood)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)

                        // Title
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Title")
                                .font(.headline)
                            TextField("Give your entry a title", text: $title)
                                .textFieldStyle(.plain)
                                .padding(12)
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(10)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)

                        // Description
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Express your thoughts")
                                .font(.headline)

                            ZStack(alignment: .topLeading) {
                                if description.isEmpty {
                                    Text("Write about your day, what happened, and how it made you feel…")
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 20)
                                }
                                TextEditor(text: $description)
                                    .padding(8)
                                    .frame(minHeight: 160)
                                    .scrollContentBackground(.hidden)
                            }
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(10)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                    }
                    .padding()
                }

                GradientButton(title: "Save", icon: "checkmark", isEnabled: canSave) {
                    guard let selectedMood else { return }
                    onSave(selectedMood, title.trimmingCharacters(in: .whitespacesAndNewlines), description.trimmingCharacters(in: .whitespacesAndNewlines), date)
                    dismiss()
                }
                .padding(.horizontal)
                .padding(.bottom, 12)
                .padding(.top, 8)
            }
        }
        .navigationTitle("New Journal Entry")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func moodButton(_ mood: JournalMood) -> some View {
        let isSelected = selectedMood == mood
        return Button {
            selectedMood = mood
        } label: {
            VStack(spacing: 6) {
                Text(mood.emoji)
                    .font(.system(size: 26))
                Text(mood.label)
                    .font(.caption2.weight(.medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isSelected ? mood.color.opacity(0.4) : Color(.secondarySystemBackground))
            .foregroundColor(isSelected ? .primary : .secondary)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? mood.color : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        CreateJournalView(onSave: { _, _, _, _ in })
    }
}
