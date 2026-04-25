import SwiftUI

struct BreathingView: View {
    
    @State private var breathe = false
    @EnvironmentObject var authVM: AuthViewModel

    @State private var startTime: Date?
    @State private var sessionEnded = false
    
    var body: some View {
        ZStack {
            
            // Background
            BlurBackground()
            
            VStack(spacing: 40) {
                
                ZStack {
                    
                    // Rounded square background
                    RoundedRectangle(cornerRadius: 40)
                        .fill(.clear)
                        .frame(width: 300, height: 300)
                        .overlay(
                            RoundedRectangle(cornerRadius: 40)
                                .stroke(Color.white.opacity(0.3), lineWidth: 15)
                        )
                    
                    // Breathing Circle
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.orange, Color.orange.opacity(1)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 180, height: 180)
                        .scaleEffect(breathe ? 1.15 : 1.0)
                        .shadow(color: .orange.opacity(0.5),
                                radius: 20, x: 0, y: 10)
                        .animation(
                            .easeInOut(duration: 4)
                            .repeatForever(autoreverses: true),
                            value: breathe
                        )
                    
                    // Face
                    VStack(spacing: 12) {
                        HStack(spacing: 20) {
                            CurvedEyeView(
                                width: 20,
                                height: 15,
                                curveAmount: 25,
                                angle: 180,
                                lineWidth: 5,
                                color: .black
                            )
                            .offset(y: breathe ? -40 : 0)   // 👈 move up
                            .animation(.easeInOut(duration: 4)
                                .repeatForever(autoreverses: true),
                                       value: breathe)
                            
                            CurvedEyeView(
                                width: 20,
                                height: 15,
                                curveAmount: 25,
                                angle: 180,
                                lineWidth: 5,
                                color: .black
                            )
                            .offset(y: breathe ? -40 : 0)
                            .animation(.easeInOut(duration: 4)
                                .repeatForever(autoreverses: true),
                                       value: breathe)
                            
                        }
                        
                        CurvedEyeView(
                            width: 120,
                            height: breathe ? 15 : 30,   // 👈 mouth becomes narrow
                            curveAmount: breathe ? 50 : 100,
                            angle: 180,
                            lineWidth: 5,
                            color: .black
                        )
                        .animation(.easeInOut(duration: 4)
                            .repeatForever(autoreverses: true),
                                   value: breathe)
                            
                    }
                }
                
                // Shadow below circle
                Ellipse()
                    .fill(Color.orange.opacity(0.3))
                    .frame(width: 140, height: 30)
                    .blur(radius: 4)
                    .offset(y: -20)
                
                // Text
                Text("30 second breathing\nexercise for relaxation")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.black.opacity(0.8))
            }
        }
        .onAppear {
            breathe = true
            startTime = Date()
            
            // Auto end session after 30 sec
            DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
                endSession()
            }
        }
    }
    
    func endSession() {
        guard !sessionEnded else { return }
        sessionEnded = true
        
        breathe = false
        
        Task {
            guard let uid = authVM.user?.uid else { return }
            
            let duration = Int(Date().timeIntervalSince(startTime ?? Date()))
            
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
                print("❌ Failed to save session:", error.localizedDescription)
            }
        }
    }
}



#Preview {
    BreathingView()
}
