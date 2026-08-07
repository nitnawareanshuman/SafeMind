//
//  ProfileView.swift
//  SafeMind
//

import SwiftUI
import Charts

struct ProfileView: View {

    @StateObject private var vm = ProfileViewModel()
    @EnvironmentObject var authVM: AuthViewModel
    let uid: String

    var body: some View {
        NavigationStack {
            ZStack {
                BlurBackground()

                ScrollView {
                    VStack(spacing: 20) {
                        profileHeader
                        moodGraphCard
                        linksSection
                        logoutButton
                    }
                    .padding()
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { vm.loadUser(uid: uid) }
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                AvatarImage(
                    photoURL: vm.user?.photoURL,
                    overrideImage: vm.selectedImage,
                    size: 100
                )
                .overlay(Circle().stroke(Color.white, lineWidth: 3))
                .shadow(radius: 6)

                Button {
                    vm.showingImagePicker = true
                } label: {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(7)
                        .background(Circle().fill(Color.blue))
                        .shadow(radius: 3)
                }
                .offset(x: 4, y: 4)
            }

            Text(vm.user?.name ?? "Loading…")
                .font(.title2.bold())

            if vm.isUploading {
                ProgressView("Saving photo…")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.top, 12)
        .sheet(isPresented: $vm.showingImagePicker) {
            ImagePicker(image: $vm.selectedImage)
                .ignoresSafeArea()
                .onDisappear {
                    if vm.selectedImage != nil {
                        vm.updateProfile { updated in
                            authVM.updateLocalProfile(updated)
                        }
                    }
                }
        }
    }

    // MARK: - Mood Graph

    private var moodGraphCard: some View {
        let points = moodPoints

        return VStack(alignment: .leading, spacing: 12) {
            Text("Mood Trend")
                .font(.headline)

            if points.isEmpty {
                Text("Complete a daily mood check-in to see your trend here.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 30)
                    .frame(maxWidth: .infinity)
            } else {
                Chart(points) { point in
                    AreaMark(
                        x: .value("Day", point.date),
                        y: .value("Wellbeing", point.score)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.teal.opacity(0.35), Color.pink.opacity(0.05)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)

                    LineMark(
                        x: .value("Day", point.date),
                        y: .value("Wellbeing", point.score)
                    )
                    .foregroundStyle(
                        LinearGradient(colors: [.teal, .pink], startPoint: .leading, endPoint: .trailing)
                    )
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))

                    PointMark(
                        x: .value("Day", point.date),
                        y: .value("Wellbeing", point.score)
                    )
                    .foregroundStyle(Color.white)
                    .symbolSize(30)
                }
                .chartYScale(domain: 0...10)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { _ in
                        AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                    }
                }
                .chartYAxis(.hidden)
                .frame(height: 160)

                if let latest = points.last {
                    HStack(spacing: 6) {
                        Circle().fill(latest.moodColor).frame(width: 8, height: 8)
                        Text(latest.moodLabel)
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.secondary)
                        Text("· today")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
    }


    // MARK: - Links

    private var linksSection: some View {
        VStack(spacing: 12) {
            profileLink(title: "Activity", icon: "chart.bar.fill", color: .blue) {
                ActivityView()
            }
            profileLink(title: "Streak", icon: "flame.fill", color: .orange) {
                StreakView()
            }
            profileLink(title: "Safe Circle", icon: "person.2.fill", color: .pink) {
                SafeCircleContactsView()
            }
        }
    }

    private func profileLink<Destination: View>(title: String, icon: String, color: Color, @ViewBuilder destination: () -> Destination) -> some View {
        NavigationLink(destination: destination()) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .frame(width: 34, height: 34)
                    .background(color.opacity(0.15))
                    .clipShape(Circle())

                Text(title)
                    .font(.body.weight(.medium))
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(16)
        }
    }

    // MARK: - Logout

    private var logoutButton: some View {
        Button(role: .destructive) {
            authVM.signOut()
        } label: {
            Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
                .font(.body.weight(.semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .cornerRadius(16)
        }
        .padding(.top, 6)
    }

    // MARK: - Mood data

    private struct MoodPoint: Identifiable {
        let date: Date
        let score: Double // 0-10, higher = better

        var id: Date { date }

        var moodLabel: String {
            switch score {
            case 8...10: return "Happy"
            case 6..<8:  return "Calm"
            case 4..<6:  return "Okay"
            case 2..<4:  return "Low"
            default:     return "Stressed"
            }
        }

        var moodColor: Color {
            switch score {
            case 8...10: return .pink
            case 6..<8:  return .teal
            case 4..<6:  return .yellow
            case 2..<4:  return .orange
            default:     return .red
            }
        }
    }

    private var moodPoints: [MoodPoint] {
        MoodHistoryStore().allEntries()
            .suffix(7)
            .map { MoodPoint(date: $0.date, score: max(0, 10 - $0.stress)) }
    }
}

#Preview {
    ProfileView(uid: "preview")
        .environmentObject(AuthViewModel())
}
