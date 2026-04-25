//
//  AccupressureView.swift
//  SafeMind
//
//  Created by Anshuman Nitnaware on 04/03/26.
//

import SwiftUI

struct AcupressurePoint: Identifiable {
    let id = UUID()
    let name: String
    let location: String
    let description: String
    let caution: String?
}

struct AcupressureDetailView: View {
    let point: AcupressurePoint
    
    @State private var seconds = 60
    @State private var running = false
    @State private var timer: Timer?
    @EnvironmentObject var authVM: AuthViewModel
    @State private var startTime: Date?
    
    var body: some View {
        ZStack {
            BlurBackground().ignoresSafeArea()
            
            VStack(spacing: 25) {
                // 👇 Updated Illustration Container
                illustrationContainer
                
                // 👇 Point Information
                VStack(alignment: .leading, spacing: 10) {
                    Text(point.name)
                        .font(.title2.bold())
                    
                    Text("📍 \(point.location)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(point.description)
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    if let caution = point.caution {
                        Text("⚠️ \(caution)")
                            .font(.footnote.bold())
                            .foregroundColor(.orange)
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(16)
                
                // 👇 Timer UI
                VStack(spacing: 12) {
                    Text("\(seconds)s")
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                    
                    Stepper("Adjust time", value: $seconds, in: 10...180, step: 10)
                        .disabled(running)
                    
                    HStack(spacing: 20) {
                        Button(running ? "Stop" : "Start") {
                            running.toggle()
                            
                            if running {
                                startTimer()
                            } else {
                                stopTimer()
                                endSession()   // 🔥 save partial session
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(running ? .red : .blue)
                        
                        Button("Reset") {
                            stopTimer()
                            running = false
                            seconds = 60
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(16)
            }
            .padding()
        }
        .navigationTitle("Point Detail")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { stopTimer() }
    }
    
    // MARK: - Illustration Builder
    
    @ViewBuilder
    private var illustrationContainer: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .frame(height: 200)
            
            if point.name.contains("LI4") {
                pointImage(name: "hegu")
            } else if point.name.contains("PC6") {
                pointImage(name: "pc6") // Ensure your asset is named "pi6"
            } else if point.name.contains("GV20") {
                pointImage(name: "gv20")
            } else {
                Image(systemName: "dot.circle.and.hand.point.up.left.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private func pointImage(name: String) -> some View {
        Image(name)
            .resizable()
            .scaledToFit()
            .frame(height: 180)
            .cornerRadius(12)
            .shadow(radius: 5)
    }

    // MARK: - Timer Logic
    private func startTimer() {
        stopTimer()
        
        // 🔥 Start session time
        startTime = Date()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if seconds > 0 {
                seconds -= 1
            } else {
                stopTimer()
                running = false
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                
                // 🔥 Save session when completed
                endSession()
            }
        }
    }
    
    func endSession() {
        Task {
            guard let uid = authVM.user?.uid else { return }
            
            let duration = Int(Date().timeIntervalSince(startTime ?? Date()))
            
            let session = Session(
                id: UUID().uuidString,
                type: "acupressure",
                duration: duration,
                date: Date()
            )
            
            do {
                try await ProfileManager.shared.saveSession(uid: uid, session: session)
                print("✅ Acupressure session saved")
            } catch {
                print("❌ Failed to save session:", error.localizedDescription)
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

struct AcupressureListView: View {
    
    let points = [
        AcupressurePoint(name: "LI4 (Hegu)", location: "Webbing between thumb and index finger", description: "Relieves headaches, stress, and facial pain.", caution: "Avoid during pregnancy."),
        AcupressurePoint(name: "PC6 (Neiguan)", location: "Three finger-breadths below the wrist crease", description: "Helps with anxiety, nausea, and motion sickness.", caution: nil),
        AcupressurePoint(name: "GV20 (Baihui)", location: "Top of the head, midpoint between ears", description: "Used for mental clarity, dizziness, and anxiety.", caution: nil)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                BlurBackground().ignoresSafeArea()
                
                List(points) { point in
                    NavigationLink(destination: AcupressureDetailView(point: point)) {
                        VStack(alignment: .leading) {
                            Text(point.name).font(.headline)
                            Text(point.location)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .listRowBackground(Color.clear)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Acupressure Points")
        }
    }
}

#Preview("LI4 Detail") {
    NavigationStack {
        AcupressureDetailView(
            point: AcupressurePoint(
                name: "LI4 (Hegu)",
                location: "Between thumb and index finger",
                description: "May help relieve stress and headaches. Apply firm pressure for 1–2 minutes.",
                caution: "Avoid during pregnancy."
            )
        )
    }
}
