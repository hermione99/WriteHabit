import SwiftUI
import FirebaseAuth

struct UsernameSetupView: View {
    @Binding var isAuthenticated: Bool
    @Binding var needsUsernameSetup: Bool
    @StateObject private var themeManager = ThemeManager.shared
    @State private var username = ""
    @State private var displayName = ""
    @State private var isChecking = false
    @State private var errorMessage: String?
    @State private var isAvailable = false
    
    private let minUsernameLength = 3
    private let maxUsernameLength = 20
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Choose Your Writing Name".localized)
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top, 40)
                
                Text("This will be your unique identity on DailyWrite".localized)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                
                VStack(spacing: 16) {
                    // Display Name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Display Name".localized)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        TextField("Your Name".localized, text: $displayName)
                            .textContentType(.name)
                            .padding()
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    // Username
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Username".localized)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        HStack {
                            Text("@")
                                .foregroundStyle(.secondary)
                            TextField("username".localized, text: $username)
                                .textContentType(.username)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .onChange(of: username) { _ in
                                    isAvailable = false
                                    errorMessage = nil
                                }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        // Validation indicators
                        HStack {
                            Image(systemName: isValidLength ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(isValidLength ? .green : .secondary)
                            Text("3-20 characters".localized)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Spacer()
                            
                            Image(systemName: isValidCharacters ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(isValidCharacters ? .green : .secondary)
                            Text("Letters, numbers, underscores only".localized)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    if let error = errorMessage {
                        Text(error)
                            .font(.subheadline)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }
                    
                    if isAvailable {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("\(username) is available!".localized)
                                .font(.subheadline)
                                .foregroundStyle(.green)
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                VStack(spacing: 12) {
                    // Check availability button
                    if !isAvailable {
                        Button {
                            checkUsernameAvailability()
                        } label: {
                            HStack {
                                if isChecking {
                                    ProgressView()
                                        .tint(.white)
                                }
                                Text("Check Availability".localized)
                                    .font(.headline)
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isValidForCheck ? Color.blue : Color.gray)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .disabled(!isValidForCheck || isChecking)
                    }
                    
                    // Continue button
                    Button {
                        createProfile()
                    } label: {
                        Text("Continue".localized)
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isAvailable ? Color.blue : Color.gray)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(!isAvailable)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
    }
    
    private var isValidLength: Bool {
        username.count >= minUsernameLength && username.count <= maxUsernameLength
    }
    
    private var isValidCharacters: Bool {
        let allowedCharacters = CharacterSet.letters.union(.decimalDigits).union(CharacterSet(charactersIn: "_"))
        return username.allSatisfy { char in
            String(char).rangeOfCharacter(from: allowedCharacters.inverted) == nil
        }
    }
    
    private var isValidForCheck: Bool {
        isValidLength && isValidCharacters && !username.isEmpty
    }
    
    private func checkUsernameAvailability() {
        isChecking = true
        errorMessage = nil
        
        Task {
            do {
                let available = try await FirebaseService.shared.isUsernameAvailable(username)
                await MainActor.run {
                    isChecking = false
                    isAvailable = available
                    if !available {
                        errorMessage = "\(username) is already taken. Try another.".localized
                    }
                }
            } catch {
                await MainActor.run {
                    isChecking = false
                    errorMessage = "Unable to check availability. Please try again.".localized
                }
            }
        }
    }
    
    private func createProfile() {
        guard let user = Auth.auth().currentUser else { return }
        
        let finalDisplayName = displayName.isEmpty ? (user.displayName ?? "Writer") : displayName
        
        Task {
            do {
                try await FirebaseService.shared.createUserProfile(
                    userId: user.uid,
                    email: user.email ?? "",
                    displayName: finalDisplayName,
                    username: username
                )
                isAuthenticated = true
                needsUsernameSetup = false
            } catch {
                errorMessage = "Failed to create profile. Please try again.".localized
            }
        }
    }
}

#Preview {
    UsernameSetupView(isAuthenticated: .constant(false), needsUsernameSetup: .constant(true))
}
