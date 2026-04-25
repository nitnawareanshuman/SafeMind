//
//  CBTView.swift
//  SafeMind
//

import SwiftUI
import SwiftData

// MARK: - SwiftData Model

@Model
final class CBTEntry {
    var date: Date
    var situation: String
    var automaticThoughts: String
    var emotions: String
    var evidenceFor: String
    var evidenceAgainst: String
    var balancedThought: String

    init(situation: String, automaticThoughts: String, emotions: String,
         evidenceFor: String, evidenceAgainst: String, balancedThought: String) {
        self.date = Date()
        self.situation = situation
        self.automaticThoughts = automaticThoughts
        self.emotions = emotions
        self.evidenceFor = evidenceFor
        self.evidenceAgainst = evidenceAgainst
        self.balancedThought = balancedThought
    }
}

// MARK: - CBTView

struct CBTView: View {

    @EnvironmentObject var authVM: AuthViewModel
    @State private var startTime: Date = Date()
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CBTEntry.date, order: .reverse) private var entries: [CBTEntry]

    @State private var situation: String = ""
    @State private var automaticThoughts: String = ""
    @State private var emotions: String = ""
    @State private var evidenceFor: String = ""
    @State private var evidenceAgainst: String = ""
    @State private var balancedThought: String = ""
    @State private var showingSaved = false
    @State private var showHistory = false

    var body: some View {
        ZStack {
            BlurBackground()

            Form {
                Section("Situation") {
                    TextField("What happened?", text: $situation, axis: .vertical)
                }
                Section("Automatic Thoughts") {
                    TextField("What went through your mind?", text: $automaticThoughts, axis: .vertical)
                }
                Section("Emotions") {
                    TextField("How did you feel? e.g., anxious 6/10", text: $emotions, axis: .vertical)
                }
                Section("Evidence For") {
                    TextField("What supports the thought?", text: $evidenceFor, axis: .vertical)
                }
                Section("Evidence Against") {
                    TextField("What does not support it?", text: $evidenceAgainst, axis: .vertical)
                }
                Section("Balanced Thought") {
                    TextField("A more balanced perspective", text: $balancedThought, axis: .vertical)
                }

                // ✅ Save actually persists via SwiftData
                Section {
                    Button {
                        saveEntry()
                    } label: {
                        Label("Save Entry", systemImage: "checkmark.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(situation.isEmpty)
                }

                // Past entries
                if !entries.isEmpty {
                    Section("Past Entries (\(entries.count))") {
                        ForEach(entries) { entry in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(entry.situation)
                                    .font(.subheadline)
                                    .lineLimit(1)
                                Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .onDelete { indexSet in
                            for i in indexSet { modelContext.delete(entries[i]) }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("CBT Thought Record")
            .overlay(alignment: .top) {
                if showingSaved {
                    Text("✅ Entry saved!")
                        .font(.caption.bold())
                        .padding(8)
                        .background(Capsule().fill(Color.green.opacity(0.85)))
                        .foregroundColor(.white)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .padding(.top, 4)
                }
            }
            .onAppear {
                startTime = Date()
            }
        }
    }

    private func saveEntry() {
        let entry = CBTEntry(
            situation: situation,
            automaticThoughts: automaticThoughts,
            emotions: emotions,
            evidenceFor: evidenceFor,
            evidenceAgainst: evidenceAgainst,
            balancedThought: balancedThought
        )
        
        modelContext.insert(entry)

        // 🔥 Calculate session duration
        let duration = Int(Date().timeIntervalSince(startTime))

        // 🔥 Save session to Firestore
        Task {
            guard let uid = authVM.user?.uid else { return }

            let session = Session(
                id: UUID().uuidString,
                type: "cbt",
                duration: duration,
                date: Date()
            )

            do {
                try await ProfileManager.shared.saveSession(uid: uid, session: session)
                print("✅ CBT session saved")
            } catch {
                print("❌ Failed to save CBT session:", error.localizedDescription)
            }
        }

        // Clear fields
        situation = ""
        automaticThoughts = ""
        emotions = ""
        evidenceFor = ""
        evidenceAgainst = ""
        balancedThought = ""

        // Flash confirmation
        withAnimation { showingSaved = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { showingSaved = false }
        }
    }
}

#Preview {
    CBTView()
        .modelContainer(for: CBTEntry.self, inMemory: true)
}
