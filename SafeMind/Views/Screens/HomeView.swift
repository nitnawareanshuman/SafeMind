//
//  HomeView.swift
//  SafeMind
//

import SwiftUI

struct HomeView: View {

    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                BlurBackground()

                ScrollView {
                    VStack(spacing: 20) {

                        // Greeting
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Welcome Back 👋")
                                .font(.title2.bold())
                            Text("How are you feeling today?")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(20)

                        // Quick Start
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Quick Start")
                                .font(.headline)
                                .padding(.leading, 4)

                            NavigationLink { BreathingView() } label: {
                                quickCard(title: "Breathing Session",    icon: "wind",             color: .blue)
                            }
                            NavigationLink { CBTView() } label: {
                                quickCard(title: "CBT Thought Record",   icon: "brain.head.profile", color: .purple)
                            }
                            NavigationLink { AcupressureListView() } label: {
                                quickCard(title: "Acupressure Points", icon: "hand.point.up", color: .orange)
                            }
                            NavigationLink {
                                MusicListView(mood: "Focus")
                            } label: {
                                quickCard(title: "Focus Mode",           icon: "headphones",       color: .green)
                            }
                        }

                        // Today
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Today")
                                .font(.headline)
                                .padding(.leading, 4)

                            infoCard(icon: "lungs.fill",     text: "Suggested: 3-minute Box Breathing",              color: .blue)
                            infoCard(icon: "lightbulb.fill", text: "Tip: Challenge unhelpful thoughts with evidence", color: .yellow)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("SafeMind")
            // ✅ Added Toolbar for Settings
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.body.bold())
                            .foregroundColor(.primary)
                            .padding(8)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                }
            }
        }
    }

    // MARK: - Components

    private func quickCard(title: String, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 40)

            Text(title).font(.body)

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(15)
    }

    private func infoCard(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 28)
            Text(text).font(.subheadline)
            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(15)
    }
}

#Preview {
    HomeView()
        .environmentObject(AuthViewModel())
}
