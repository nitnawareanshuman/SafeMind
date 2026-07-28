// AccupressureView.swift

import SwiftUI
import SceneKit

// MARK: - Main View
struct AccupressureView: View {
    
    @State private var selectedPoint: AcupressurePoint? = nil
    @State private var showDetail = false
    @State private var coordinator: HumanBodySceneView.Coordinator?
    @EnvironmentObject var authVM: AuthViewModel
    
    let points: [AcupressurePoint] = [
        AcupressurePoint(
            name: "He Gu (Union Valley Point)",
            location: "Back of the hand, in the webbing between the thumb and index finger",
            description: "Relieves headaches, stress, facial pain, and tension. Place your opposite thumb in the webbing between your thumb and index finger and apply firm, circular pressure for 1–3 minutes. Breathe slowly and deeply while pressing. Repeat on the other hand.",
            caution: "Avoid during pregnancy, as this point may stimulate uterine contractions.",
            scenePosition: SCNVector3(-0.27816448, -0.053396154, 0.098935165),
            cameraZoomPosition: SCNVector3(-0.27, -0.05-0.3, 2.0)
        ),
        AcupressurePoint(
            name: "Neiguan (Inner Frontier Gate)",
            location: "Inner forearm, two finger-widths above the wrist crease, between the two central tendons",
            description: "Helps reduce anxiety, nausea, motion sickness, and palpitations. Turn your palm upward and place two fingers above your wrist crease — the point lies between the two visible tendons. Apply steady thumb pressure for 1–3 minutes while breathing slowly. Repeat on the other wrist.",
            caution: nil,
            scenePosition: SCNVector3(x: 0.20360059, y: 0.18076682, z: -0.002612133),
            cameraZoomPosition: SCNVector3(0.20, 0.18-0.3, 2.0)
        ),
        AcupressurePoint(
            name: "Yintang (Third Eye Point)",
            location: "Midpoint between the eyebrows, just above the bridge of the nose",
            description: "A calming point commonly used to reduce stress, anxiety, restlessness, and promote relaxation. Apply gentle circular pressure with your middle finger for 1–3 minutes while breathing slowly and deeply.",
            caution: "Use gentle pressure only. Avoid pressing on irritated, injured, or inflamed skin.",
            scenePosition: SCNVector3(x: -0.046152476, y: 0.82705224, z: 0.14648384),
            cameraZoomPosition: SCNVector3(-0.05, 0.82-0.3, 2.0)
        ),
        AcupressurePoint(
            name: "Shen Men (Heavenly Gate Point)",
            location: "Upper ear, in the triangular fossa near the top center of the ear",
            description: "A well-known calming point that may help reduce stress, anxiety, insomnia, and emotional tension. Apply gentle pressure or massage for 1–3 minutes while taking slow, deep breaths.",
            caution: "Avoid excessive pressure if the ear is injured, infected, or recently pierced.",
            scenePosition: SCNVector3(x: 0.03889088, y: 0.82429653, z: 0.012358077),
            cameraZoomPosition: SCNVector3(0.04, 0.82-0.3, 2.0)
        ),
        AcupressurePoint(
            name: "Tai Chong (Great Surge Point)",
            location: "Top of foot between big toe and second toe",
            description: "Helps reduce stress, anxiety, irritability, and tension. Press for 1–3 minutes on each foot.",
            caution: "Avoid if the area is injured or inflamed.",
            scenePosition: SCNVector3(x: 0.1657193, y: -0.9282139, z: 0.10464109),
            cameraZoomPosition: SCNVector3(0.16, -0.92-0.2, 2.0)
        ),
        AcupressurePoint(
            name: "Jian Jing (Shoulder Well point)",
            location: "Top of the shoulder, midway between the base of the neck and the outer edge of the shoulder",
            description: "Often used to relieve stress, neck and shoulder tension, headaches, and mental fatigue. Apply firm, comfortable pressure for 1–2 minutes while taking slow, deep breaths.",
            caution: "Avoid strong stimulation during pregnancy, as this point is traditionally contraindicated for pregnant individuals. Do not apply pressure to injured or inflamed areas.",
            scenePosition: SCNVector3(x: 0.056206178, y: 0.67352146, z: -0.0091450615),
            cameraZoomPosition: SCNVector3(0.06, 0.67-0.3, 2.0)
        )
    ]
    
    var body: some View {
        ZStack {
            BlurBackground().ignoresSafeArea()
            
            // Title (scene ke peeche)
            VStack {
                Text("Acupressure Points")
                    .font(.title.bold())
                    .padding(.top, 60)
                    .padding(.horizontal)
                Spacer()
            }
            
            // 3D Scene
            HumanBodySceneView(points: points) { tappedPoint in
                withAnimation(.spring()) {
                    selectedPoint = tappedPoint
                    showDetail = true
                }
            } onReady: { coord in
                DispatchQueue.main.async {
                    self.coordinator = coord
                }
            }
            .ignoresSafeArea()
            
            
            // Detail Panel
            if showDetail, let point = selectedPoint {
                VStack {
                    Spacer()
                    detailPanel(point: point)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .navigationBarHidden(showDetail)
    }
    
    // MARK: - Detail Panel
    @ViewBuilder
    private func detailPanel(point: AcupressurePoint) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.secondary.opacity(0.4))
                .frame(width: 40, height: 5)
                .frame(maxWidth: .infinity)
            
            Text(point.name)
                .font(.title2.bold())
            
            Text("📍 \(point.location)")
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Text(point.description)
                .font(.body)
            
            if let caution = point.caution {
                Text("⚠️ \(caution)")
                    .font(.footnote.bold())
                    .foregroundColor(.red)
            }
            
            AcupressureTimerView(point: point)
                .environmentObject(authVM)
            
            Button {
                print("Back Button Tapped")
                withAnimation(.spring()) {
                    showDetail = false
                    selectedPoint = nil
                }
                coordinator?.resetCamera()
            } label: {
                Label("Back to Body", systemImage: "arrow.left")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.secondary.opacity(0.2))
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(24)
        .padding()
    }
}

// MARK: - Timer Subview
struct AcupressureTimerView: View {
    let point: AcupressurePoint
    @EnvironmentObject var authVM: AuthViewModel
    
    @State private var seconds = 60
    @State private var running = false
    @State private var timer: Timer?
    @State private var startTime: Date?
    
    var body: some View {
        HStack {
            Text(timeString)
                .font(.title3.monospacedDigit())
                .foregroundColor(running ? .green : .primary)
            
            Spacer()
            
            Button {
                running ? stopTimer() : startTimer()
                running.toggle()
            } label: {
                Image(systemName: running ? "pause.fill" : "play.fill")
                    .padding(10)
                    .background(running ? Color.red.opacity(0.2) : Color.green.opacity(0.2))
                    .cornerRadius(10)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
        .onDisappear { stopTimer() }
    }
    
    private var timeString: String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
    
    private func startTimer() {
        startTime = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if seconds > 0 {
                seconds -= 1
            } else {
                stopTimer()
                running = false
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                endSession()
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func endSession() {
        Task {
            guard let uid = authVM.user?.uid else { return }
            let duration = Int(Date().timeIntervalSince(startTime ?? Date()))
            let session = Session(
                id: UUID().uuidString,
                type: "acupressure",
                duration: duration,
                date: Date()
            )
            try? await ProfileManager.shared.saveSession(uid: uid, session: session)
        }
    }
}

#Preview {
    AccupressureView()
        .environmentObject(AuthViewModel())
}
