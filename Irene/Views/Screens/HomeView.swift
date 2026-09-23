//
//  HomeView.swift
//  Irene
//

import SwiftUI

struct HomeView: View {

    @EnvironmentObject var authVM: AuthViewModel

    private var firstName: String {
        let full = authVM.profile?.name ?? ""
        let first = full.split(separator: " ").first.map(String.init) ?? full
        return first.isEmpty ? "there" : first
    }

    private let tools: [(title: String, subtitle: String, icon: String, color: Color)] = [
        ("Box Breathing", "Slow down, reset", "wind", .blue),
        ("Journal", "Write it out", "book.fill", .purple),
        ("Acupressure", "Guided pressure points", "hand.point.up.left.fill", .orange),
        ("Music", "Sounds to focus or unwind", "headphones", .green),
        ("Read Article", "Bite-sized wellness reads", "text.book.closed.fill", .pink)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                BlurBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        //Header
                        Header(
                            photoURL: authVM.profile?.photoURL,
                            uid: authVM.user?.uid ?? ""
                        )

                        // Greeting
                        HStack {
                            Text("Hello, \(firstName) 👋")
                                .font(.title.bold())
                            Spacer()
                        }
                        .padding(.top, 4)

                        // Mood Check-In — full-width rectangle
                        NavigationLink {
                            MoodCheckInChatView()
                        } label: {
                            moodCheckInBlock
                        }
                        .buttonStyle(.plain)

                        // Wellness Tools — full-width rectangle rows, no gaps
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Wellness Tools")
                                .font(.title3.bold())
                                .padding(.leading, 4)

                            VStack(spacing: 14) {
                                NavigationLink { BreathingView() } label: {
                                    toolRow(tools[0])
                                }
                                NavigationLink { JournalView() } label: {
                                    toolRow(tools[1])
                                }
                                NavigationLink { AccupressureView() } label: {
                                    toolRow(tools[2])
                                }
                                NavigationLink { MusicListView() } label: {
                                    toolRow(tools[3])
                                }
                                NavigationLink { ArticlesListView() } label: {
                                    toolRow(tools[4])
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
            }
            .stressCheckAlert()
        }
    }

    // MARK: - Mood Check-In (full-width rectangle)

    private var moodCheckInBlock: some View {
        HStack(spacing: 16) {
            Image(systemName: "face.smiling.inverse")
                .font(.system(size: 30))
                .foregroundColor(.yellow)
                .frame(width: 56, height: 56)
                .background(Color.black.opacity(0.4))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text("Mood Check-In")
                    .font(.headline)
                    .foregroundColor(.primary)
                Text("How are you feeling right now?")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.4))
        .cornerRadius(24)
    }

    // MARK: - Wellness Tool row (full-width rectangle)

    private func toolRow(_ tool: (title: String, subtitle: String, icon: String, color: Color)) -> some View {
        HStack(spacing: 16) {
            Image(systemName: tool.icon)
                .font(.system(size: 20))
                .foregroundColor(tool.color)
                .frame(width: 48, height: 48)
                .background(tool.color.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(tool.title)
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.primary)
                Text(tool.subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
    }
}

#Preview {
    HomeView()
        .environmentObject(AuthViewModel())
}
