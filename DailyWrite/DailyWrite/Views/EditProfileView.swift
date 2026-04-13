import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var displayName = ""
    @State private var bio = ""
    @State private var blogUrl = ""
    @State private var brunchUrl = ""
    @State private var instagramUrl = ""
    @State private var twitterUrl = ""
    @State private var threadsUrl = ""
    @State private var isSaving = false
    @State private var showConfirmation = false
    @State private var userProfile: UserProfile?
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Profile Info".localized) {
                    TextField("Display Name".localized, text: $displayName)
                        .textContentType(.name)
                    
                    if let profile = userProfile {
                        HStack {
                            Text("@")
                                .foregroundStyle(.secondary)
                            Text(profile.username)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                    }
                }
                
                Section("Bio".localized) {
                    TextEditor(text: $bio)
                        .frame(minHeight: 100)
                }
                
                Section("Links".localized) {
                    TextField("Blog URL".localized, text: $blogUrl)
                        .textContentType(.URL)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    
                    TextField("Brunch URL".localized, text: $brunchUrl)
                        .textContentType(.URL)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    
                    TextField("Instagram".localized, text: $instagramUrl)
                        .textContentType(.URL)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    
                    TextField("Twitter/X".localized, text: $twitterUrl)
                        .textContentType(.URL)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    
                    TextField("Threads".localized, text: $threadsUrl)
                        .textContentType(.URL)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
                
                Section {
                    Button {
                        showConfirmation = true
                    } label: {
                        HStack {
                            Spacer()
                            if isSaving {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text("Save Changes".localized)
                                .font(.headline)
                            Spacer()
                        }
                    }
                    .foregroundStyle(.white)
                    .listRowBackground(hasChanges ? Color.blue : Color.gray)
                    .disabled(!hasChanges || isSaving)
                }
            }
            .navigationTitle("Edit Profile".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel".localized) {
                        dismiss()
                    }
                }
            }
            .task {
                await loadProfile()
            }
            .alert("Save Changes?".localized, isPresented: $showConfirmation) {
                Button("Cancel".localized, role: .cancel) { }
                Button("Save".localized) {
                    saveProfile()
                }
            }
        }
    }
    
    private var hasChanges: Bool {
        guard let profile = userProfile else { return false }
        return displayName != profile.displayName
            || bio != profile.bio
            || blogUrl != (profile.blogUrl ?? "")
            || brunchUrl != (profile.brunchUrl ?? "")
            || instagramUrl != (profile.instagramUrl ?? "")
            || twitterUrl != (profile.twitterUrl ?? "")
            || threadsUrl != (profile.threadsUrl ?? "")
    }
    
    private func loadProfile() async {
        guard let user = Auth.auth().currentUser else { return }
        do {
            userProfile = try await FirebaseService.shared.getUserProfile(userId: user.uid)
            if let profile = userProfile {
                displayName = profile.displayName
                bio = profile.bio
                blogUrl = profile.blogUrl ?? ""
                brunchUrl = profile.brunchUrl ?? ""
                instagramUrl = profile.instagramUrl ?? ""
                twitterUrl = profile.twitterUrl ?? ""
                threadsUrl = profile.threadsUrl ?? ""
            }
        } catch {
            print("Error loading profile: \(error)")
        }
    }
    
    private func saveProfile() {
        guard let user = Auth.auth().currentUser else { return }
        isSaving = true
        
        Task {
            do {
                try await FirebaseService.shared.updateUserProfile(
                    userId: user.uid,
                    displayName: displayName,
                    bio: bio,
                    blogUrl: blogUrl,
                    brunchUrl: brunchUrl,
                    instagramUrl: instagramUrl,
                    twitterUrl: twitterUrl,
                    threadsUrl: threadsUrl
                )
                await MainActor.run {
                    isSaving = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                }
            }
        }
    }
}

#Preview {
    EditProfileView()
}
