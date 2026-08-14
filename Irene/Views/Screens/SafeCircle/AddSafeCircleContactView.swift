//
//  AddSafeCircleContactView.swift
//  Irene
//
//  Part of the Safe Circle feature.
//
//  Two modes, same view:
//   - Onboarding (`isOnboarding: true`): shown once right after sign-up, has
//     a "Skip" + "Continue" bottom bar, calls `onFinish` when done.
//   - Manage (default): pushed from Settings to add/remove contacts any time,
//     changes save immediately, normal back button.
//

import SwiftUI

struct AddSafeCircleContactView: View {

    @StateObject private var viewModel = SafeCircleViewModel()

    var isOnboarding: Bool = false
    var onFinish: (() -> Void)? = nil

    var body: some View {
        ZStack {
            BlurBackground().ignoresSafeArea()

            VStack(spacing: 24) {
                header

                if viewModel.contacts.isEmpty {
                    emptyState
                } else {
                    contactList
                }

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                if viewModel.canAddMore {
                    addButton
                }

                Spacer()

                if isOnboarding {
                    onboardingBottomBar
                }
            }
            .padding(.top, isOnboarding ? 50 : 24)
        }
        .navigationTitle(isOnboarding ? "" : "Safe Circle")
        .navigationBarBackButtonHidden(isOnboarding)
        .toolbar(isOnboarding ? .hidden : .automatic, for: .navigationBar)
        .sheet(isPresented: $viewModel.showContactPicker) {
            ContactPickerView { contact in
                viewModel.addContact(contact)
            }
            .ignoresSafeArea()
        }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.2.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(
                    .blue
                )

            Text("Build your Safe Circle")
                .font(.title2.bold())

            Text("Add 1–3 close friends. If Irene notices you've seemed low for a few days, it'll gently offer to help you reach out to one of them.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 32))
                .foregroundColor(.secondary)
            Text("No close friends added yet")
                .foregroundColor(.secondary)
                .font(.subheadline)
        }
        .padding(.vertical, 12)
    }

    private var contactList: some View {
        VStack(spacing: 12) {
            ForEach(viewModel.contacts) { contact in
                HStack(spacing: 14) {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Text(initials(for: contact.name))
                                .font(.subheadline.bold())
                                .foregroundColor(.blue)
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(contact.name)
                            .font(.system(size: 15, weight: .semibold))
                        Text(contact.phoneNumber)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Button {
                        viewModel.removeContact(contact)
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(.red)
                            .font(.system(size: 20))
                    }
                }
                .padding(12)
                .background(.ultraThinMaterial)
                .cornerRadius(14)
            }
        }
        .padding(.horizontal)
    }

    private var addButton: some View {
        Button {
            viewModel.errorMessage = nil
            viewModel.showContactPicker = true
        } label: {
            Label("Add from Contacts", systemImage: "person.crop.circle.badge.plus")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    .ultraThickMaterial
                )
                .cornerRadius(14)
        }
        .padding(.horizontal)
    }

    private var onboardingBottomBar: some View {
        VStack(spacing: 12) {
            GradientButton(
                title: viewModel.contacts.isEmpty ? "Skip for now" : "Continue",
                icon: viewModel.contacts.isEmpty ? nil : "arrow.right"
            ) {
                viewModel.markOnboardingSeen()
                onFinish?()
            }

            if !viewModel.contacts.isEmpty {
                Button("Skip") {
                    viewModel.markOnboardingSeen()
                    onFinish?()
                }
                .font(.footnote)
                .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 20)
    }

    private func initials(for name: String) -> String {
        let letters = name.split(separator: " ").prefix(2).compactMap { $0.first }
        return String(letters).uppercased()
    }
}

#Preview {
    NavigationStack {
        AddSafeCircleContactView(isOnboarding: true, onFinish: {})
    }
}

#Preview("Manage mode") {
    NavigationStack {
        AddSafeCircleContactView()
    }
}
