import SwiftUI

struct BreathingView: View {

    @EnvironmentObject var authVM: AuthViewModel

    @State private var phase: BreathingPhase = .pause
    @State private var circleScale: CGFloat = 1.0
    @State private var glowRadius: CGFloat = 15

    @State private var isRunning = false
    @State private var sessionEnded = false
    @State private var startTime: Date?

    @State private var timer: Timer? = nil
    @State private var currentElapsedSeconds: Double = 0.0
    private let totalCycleDuration: Double = 16.0

    private let boxSize: CGFloat = 300
    private let cornerRadius: CGFloat = 40

    var body: some View {
        ZStack {
            BlurBackground()

            VStack(spacing: 0) {

                Spacer()

                // ── Animated circle + shadow ──────────────────────────
                ZStack {
                    // Box border
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(Color.white.opacity(0.45), lineWidth: 3)
                        .frame(width: boxSize, height: boxSize)

                    // Main breathing circle
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.orange.opacity(0.95), Color.orange.opacity(0.65)],
                                center: .center,
                                startRadius: 10,
                                endRadius: 90
                            )
                        )
                        .frame(width: 180, height: 180)
                        .scaleEffect(circleScale)
                        .shadow(color: .orange.opacity(0.55), radius: glowRadius, x: 0, y: 0)
                        .overlay(
                            // Face
                            VStack(spacing: 0) {
                                faceOverlay
                            }
                        )
                }
                .frame(width: boxSize, height: boxSize)

                // Drop shadow below box
                Ellipse()
                    .fill(Color.orange.opacity(0.25))
                    .frame(width: 120 * circleScale, height: 18)
                    .blur(radius: 8)
                    .offset(y: -30)
                    .animation(.linear(duration: 0.1), value: circleScale)

                Spacer()

                // ── Phase label + instruction ─────────────────────────
                VStack(spacing: 4) {
                    Text(phase.title)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.black)

                    Text(phase.instruction)
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(.black.opacity(0.55))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 36)
                .offset(y: -50)

                // ── Start / Stop button ───────────────────────────────
                Button {
                    isRunning ? stopSession() : startSession()
                } label: {
                    Text(isRunning ? "Stop Session" : "Start Session")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(isRunning ? Color.red.opacity(0.85) : Color.green)
                                .shadow(color: (isRunning ? Color.red : Color.orange).opacity(0.4),
                                        radius: 12, x: 0, y: 6)
                        )
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
        }
    }

    // MARK: - Face overlay (kept from original if present, simplified here)
    @ViewBuilder
    private var faceOverlay: some View {
        BreathingFaceView(phase: phase, circleScale: circleScale)
            .animation(.easeInOut(duration: 0.6), value: phase)
    }

    // MARK: - Session Management

    func startSession() {
        sessionEnded = false
        startTime = Date()
        currentElapsedSeconds = 0.0
        isRunning = true
        startTimer()
    }

    func stopSession() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        endSession()
        phase = .pause
        withAnimation(.easeInOut(duration: 0.4)) {
            circleScale = 1.0
            glowRadius = 15
        }
    }

    func endSession() {
        guard !sessionEnded, let start = startTime else { return }
        sessionEnded = true
        Task {
            guard let uid = authVM.user?.uid else { return }
            let duration = Int(Date().timeIntervalSince(start))
            let session = Session(
                id: UUID().uuidString,
                type: "breathing",
                duration: duration,
                date: Date()
            )
            do {
                try await ProfileManager.shared.saveSession(uid: uid, session: session)
                print("✅ Breathing session saved")
            } catch {
                print(error.localizedDescription)
            }
        }
    }

    // MARK: - Timer

    private func startTimer() {
        timer = Timer(timeInterval: 0.1, repeats: true) { _ in
            guard isRunning else { return }
            currentElapsedSeconds += 0.1
            updateBreathingPhase()
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    private func updateBreathingPhase() {
        let progress = min(
            currentElapsedSeconds.truncatingRemainder(dividingBy: totalCycleDuration),
            totalCycleDuration - 0.001
        )
        switch progress {
        case 0..<4:
            if phase != .inhale {
                phase = .inhale
                withAnimation(.linear(duration: 4.0)) { circleScale = 1.25; glowRadius = 35 }
            }
        case 4..<8:
            if phase != .hold { phase = .hold }
        case 8..<12:
            if phase != .exhale {
                phase = .exhale
                withAnimation(.linear(duration: 4.0)) { circleScale = 1.0; glowRadius = 15 }
            }
        default:
            if phase != .holdAfterExhale { phase = .holdAfterExhale }
        }
    }
}

// MARK: - Phase Definitions

enum BreathingPhase {
    case inhale, hold, exhale, holdAfterExhale, pause

    var title: String {
        switch self {
        case .inhale: return "Inhale"
        case .hold, .holdAfterExhale: return "Hold"
        case .exhale: return "Exhale"
        case .pause: return "Ready"
        }
    }

    var instruction: String {
        switch self {
        case .inhale: return "Breathe in slowly for 4 seconds"
        case .hold, .holdAfterExhale: return "Hold your breath for 4 seconds"
        case .exhale: return "Release slowly for 4 seconds"
        case .pause: return "Press Start when you're ready"
        }
    }
}

#Preview {
    BreathingView()
        .environmentObject(AuthViewModel())
}
