//
//  SafeCircleContactsView.swift
//  Irene
//
//  Part of the Safe Circle feature.
//
//  Shown when the user responds positively to the stress-check alert (or
//  taps into Safe Circle from Settings). Each saved close friend gets a
//  Call button (opens the Phone app with the number on the dialer) and a
//  Text button (opens Messages with a new conversation to that friend).
//

import SwiftUI

struct SafeCircleContactsView: View {

    @StateObject private var viewModel = SafeCircleViewModel()

    var subtitle: String = "You don't have to go through this alone — reach out to someone you trust."

    var body: some View {
        ZStack {
            BlurBackground().ignoresSafeArea()

            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Your Safe Circle")
                        .font(.title2.bold())
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.top, 12)

                if viewModel.contacts.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: 14) {
                            ForEach(viewModel.contacts) { contact in
                                ContactActionRow(contact: contact)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 4)
                    }
                }

                Spacer()
            }
        }
        .navigationTitle("Safe Circle")
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text("You haven't added any close friends yet.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 32)
                .padding(.bottom, 20)
            

            NavigationLink {
                AddSafeCircleContactView()
            } label: {
                Label("Add a close friend", systemImage: "plus")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 100)
                    .padding(.vertical, 20)
                    .background(
                        .ultraThickMaterial
                    )
                    .cornerRadius(12)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }
}

/// A single close friend row with Call / Text quick actions.
private struct ContactActionRow: View {
    let contact: SafeCircleContact

    var body: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 46, height: 46)
                .overlay(
                    Text(initials)
                        .font(.headline)
                        .foregroundColor(.blue)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(contact.name)
                    .font(.system(size: 16, weight: .semibold))
                Text(contact.phoneNumber)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: call) {
                Image(systemName: "phone.fill")
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.green)
                    .clipShape(Circle())
            }

            Button(action: text) {
                Image(systemName: "message.fill")
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.blue)
                    .clipShape(Circle())
            }
        }
        .padding(14)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }

    private var initials: String {
        let letters = contact.name.split(separator: " ").prefix(2).compactMap { $0.first }
        return String(letters).uppercased()
    }

    /// Opens the system Phone app with the friend's number already entered
    /// on the dialer/confirmation screen.
    private func call() {
        guard let url = URL(string: "tel://\(contact.dialableNumber)") else { return }
        UIApplication.shared.open(url)
    }

    /// Opens the system Messages app with a new conversation to this friend
    /// already open, ready to type.
    private func text() {
        guard let url = URL(string: "sms:\(contact.dialableNumber)") else { return }
        UIApplication.shared.open(url)
    }
}

#Preview {
    NavigationStack {
        SafeCircleContactsView()
    }
}
