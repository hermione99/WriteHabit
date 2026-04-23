import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var themeManager = ThemeManager.shared
    @State private var displayName = ""
    @State private var blogUrl = ""
    @State private var brunchUrl = ""
    @State private var instagramUrl = ""
    @State private var twitterUrl = ""
    @State private var threadsUrl = ""
    @State private var isSaving = false
    @State private var userProfile: UserProfile?
    
    // Profile image
    @State private var selectedProfileImage: UIImage?
    @State private var isUploadingImage = false
    @State private var newProfilePhotoUrl: String?
    @State private var imageUploadSuccess = false  // Force view refresh
    @State private var showPhotoChangeAlert = false  // Show confirmation after photo select
    
    var body: some View {
        // Force view refresh when image changes
        let _ = imageUploadSuccess
        let _ = selectedProfileImage
        
        NavigationStack {
            Form {
                // Profile Image Section
                Section {
                    HStack {
                        Spacer()
                        ProfileImagePicker(
                            selectedImage: $selectedProfileImage,
                            isLoading: $isUploadingImage
                        ) { image in
                            await uploadProfileImage(image)
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }
                
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
                        saveProfile()
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
                    .listRowBackground(hasChanges ? themeManager.accent : Color.gray)
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
            .alert("Photo Changed".localized, isPresented: $showPhotoChangeAlert) {
                Button("OK".localized, role: .cancel) { }
            } message: {
                Text("Your profile photo has been updated. Tap 'Save Changes' to confirm.".localized)
            }
        }
    }
    
    private var hasChanges: Bool {
        // Force refresh
        let _ = imageUploadSuccess
        let _ = selectedProfileImage
        
        guard let profile = userProfile else { 
            print("hasChanges: no profile, selectedImage: \(selectedProfileImage != nil)")
            return selectedProfileImage != nil || newProfilePhotoUrl != nil
        }
        let hasDisplayNameChange = displayName != profile.displayName
        let hasPhotoChange = newProfilePhotoUrl != profile.profilePhotoUrl || selectedProfileImage != nil
        let hasLinkChanges = blogUrl != (profile.blogUrl ?? "")
            || brunchUrl != (profile.brunchUrl ?? "")
            || instagramUrl != (profile.instagramUrl ?? "")
            || twitterUrl != (profile.twitterUrl ?? "")
            || threadsUrl != (profile.threadsUrl ?? "")
        
        let result = hasDisplayNameChange || hasPhotoChange || hasLinkChanges
        // print("hasChanges: debug removed")
        return result
    }
    
    private func uploadProfileImage(_ image: UIImage) async {
        print("uploadProfileImage: STARTING")
        guard let userId = Auth.auth().currentUser?.uid else { 
            print("uploadProfileImage: FAILED - no userId")
            return 
        }
        print("uploadProfileImage: userId = \(userId)")
        
        isUploadingImage = true
        
        do {
            print("uploadProfileImage: Uploading to ProfileImageUploader...")
            let imageUrl = try await ProfileImageUploader.shared.uploadProfileImage(image, userId: userId)
            print("uploadProfileImage: Got URL: \(imageUrl.prefix(30))...")
            await MainActor.run {
                newProfilePhotoUrl = imageUrl
                imageUploadSuccess.toggle()
                showPhotoChangeAlert = true  // Show confirmation alert
                print("uploadProfileImage: Set newProfilePhotoUrl, newUrl = \(newProfilePhotoUrl != nil)")
            }
            print("Profile image uploaded successfully: \(imageUrl.prefix(50))...")
        } catch {
            print("Error uploading profile image: \(error)")
        }
        
        isUploadingImage = false
        print("uploadProfileImage: DONE")
    }
    
    private func saveProfile() {
        guard let userId = Auth.auth().currentUser?.uid, let profile = userProfile else { 
            print("saveProfile: FAILED - userId: \(Auth.auth().currentUser?.uid ?? "nil"), profile: \(userProfile != nil)")
            return 
        }
        
        print("saveProfile: STARTING - newPhotoUrl: \(newProfilePhotoUrl != nil), profilePhotoUrl: \(profile.profilePhotoUrl != nil)")
        isSaving = true
        
        Task {
            do {
                // Delete old image if new one was uploaded
                if let newUrl = newProfilePhotoUrl, newUrl != profile.profilePhotoUrl {
                    print("saveProfile: Deleting old image...")
                    await ProfileImageUploader.shared.deleteOldProfileImage(profile.profilePhotoUrl)
                }
                
                // Update profile fields
                print("saveProfile: Updating profile fields...")
                try await FirebaseService.shared.updateUserProfile(
                    userId: userId,
                    displayName: displayName,
                    blogUrl: blogUrl.isEmpty ? nil : blogUrl,
                    brunchUrl: brunchUrl.isEmpty ? nil : brunchUrl,
                    instagramUrl: instagramUrl.isEmpty ? nil : instagramUrl,
                    twitterUrl: twitterUrl.isEmpty ? nil : twitterUrl,
                    threadsUrl: threadsUrl.isEmpty ? nil : threadsUrl
                )
                
                // Also update profile photo URL separately
                if let newUrl = newProfilePhotoUrl, newUrl != profile.profilePhotoUrl {
                    print("saveProfile: Saving photo URL...")
                    try await FirebaseService.shared.updateUserProfilePhoto(userId: userId, photoUrl: newUrl)
                    print("saveProfile: Photo URL saved successfully")
                } else {
                    print("saveProfile: SKIPPING photo save - newUrl: \(newProfilePhotoUrl != nil), same as old: \(newProfilePhotoUrl == profile.profilePhotoUrl)")
                }
                
                print("saveProfile: SUCCESS - dismissing")
                await MainActor.run {
                    isSaving = false
                    dismiss()
                }
            } catch {
                print("saveProfile: ERROR - \(error)")
                await MainActor.run {
                    isSaving = false
                }
            }
        }
    }
    
    private func loadProfile() async {
        guard let user = Auth.auth().currentUser else { 
            print("loadProfile: no current user")
            return 
        }
        print("loadProfile: loading for user \(user.uid)")
        do {
            userProfile = try await FirebaseService.shared.getUserProfile(userId: user.uid)
            print("loadProfile: profile loaded - \(userProfile != nil ? "success" : "nil")")
            if let profile = userProfile {
                displayName = profile.displayName
                blogUrl = profile.blogUrl ?? ""
                brunchUrl = profile.brunchUrl ?? ""
                instagramUrl = profile.instagramUrl ?? ""
                twitterUrl = profile.twitterUrl ?? ""
                threadsUrl = profile.threadsUrl ?? ""
                newProfilePhotoUrl = profile.profilePhotoUrl
            }
        } catch {
            print("Error loading profile: \(error)")
        }
    }
}

#Preview {
    EditProfileView()
}
