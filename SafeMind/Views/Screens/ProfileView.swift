//
//  ProfileView.swift
//  SafeMind
//

import SwiftUI

struct ProfileView: View {

    @StateObject private var vm = ProfileViewModel()
    @EnvironmentObject var authVM: AuthViewModel
    let uid: String

    var body: some View {
        // ✅ navigationTitle must be INSIDE NavigationStack, not after it
        NavigationStack {
            ZStack {
                BlurBackground()

                ScrollView {
                    VStack(spacing: 20) {
                        profileHeader
                        statsCard
                        streakCard
                        progressCard
                    }
                    .padding()
                }
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: SettingsView().environmentObject(authVM)) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.primary)
                    }
                }
            }
            NavigationLink {
                SessionHistoryView()
                    .environmentObject(authVM)
            } label: {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                    Text("View Session History")
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .padding()
                .background(Color.white.opacity(0.9))
                .cornerRadius(16)
            }
            .onAppear { vm.loadUser(uid: uid) }
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                // ✅ Show real photo from Firebase Storage URL if available
                Group {
                    if let photoURL = vm.user?.photoURL, !photoURL.isEmpty,
                       let url = URL(string: photoURL) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable().scaledToFill()
                            case .failure(_):
                                placeholderAvatar
                            default:
                                ProgressView()
                            }
                        }
                    } else if let picked = vm.selectedImage {
                        Image(uiImage: picked)
                            .resizable()
                            .scaledToFill()
                    } else {
                        placeholderAvatar
                    }
                }
                .frame(width: 100, height: 100)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white, lineWidth: 3))
                .shadow(radius: 6)

                // ✅ Camera button to pick + upload a new photo
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

            Text("Joined \(formattedDate(vm.user?.joinedDate))")
                .font(.subheadline)
                .foregroundColor(.secondary)

            // Upload progress indicator
            if vm.isUploading {
                ProgressView("Uploading photo…")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.top, 20)
        .sheet(isPresented: $vm.showingImagePicker) {
            ImagePicker(image: $vm.selectedImage)
                .ignoresSafeArea()
                .onDisappear {
                    if vm.selectedImage != nil {
                        vm.updateProfile()   // ✅ auto-upload on pick
                    }
                }
        }
    }

    // MARK: - Stats Card

    private var statsCard: some View {
        VStack(spacing: 12) {
            Text("Activity")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            statRow(icon: "clock",        title: "Avg session",         value: "\(vm.user?.avgSession ?? 0) min")
            statRow(icon: "timer",         title: "Total time",          value: "\(vm.user?.totalTime ?? 0) min")
            statRow(icon: "checkmark.seal",title: "Sessions completed",  value: "\(vm.user?.sessionsCompleted ?? 0)")
        }
        .padding()
        .background(Color.white.opacity(0.9))
        .cornerRadius(16)
    }

    // MARK: - Streak Card

    private var streakCard: some View {
        HStack(spacing: 16) {
            Image(systemName: "flame.fill")
                .font(.largeTitle)
                .foregroundColor(.orange)

            VStack(alignment: .leading, spacing: 4) {
                Text("Run Streak")
                    .font(.headline)
                Text("A few minutes a day keeps your streak alive 🔥")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.9))
        .cornerRadius(16)
    }

    // MARK: - Progress Card

    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("My Progress")
                .font(.headline)

            Text("How are you feeling today?")
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack(spacing: 12) {
                Button("Start check-in") {}
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)

                Button("Skip for now") {}
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color(.systemGray5))
                    .cornerRadius(10)
            }
        }
        .padding()
        .background(Color.white.opacity(0.9))
        .cornerRadius(16)
    }

    // MARK: - Helpers

    private var placeholderAvatar: some View {
        Circle()
            .fill(Color(.systemGray4))
            .overlay(
                Image(systemName: "person.fill")
                    .font(.largeTitle)
                    .foregroundColor(.white)
            )
    }

    private func statRow(icon: String, title: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            Text(title)
            Spacer()
            Text(value).fontWeight(.semibold)
        }
    }

    private func formattedDate(_ date: Date?) -> String {
        guard let date else { return "" }
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: date)
    }
}

// MARK: - ImagePicker (UIKit wrapper)

struct ImagePicker: UIViewControllerRepresentable {

    @Binding var image: UIImage?

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let img = info[.originalImage] as? UIImage { parent.image = img }
            picker.dismiss(animated: true)
        }
    }
}

#Preview {
    ProfileView(uid: "preview")
        .environmentObject(AuthViewModel())
}
