import SwiftUI
import UIKit
import FirebaseAuth
import FirebaseFirestore

struct ProfileImagePicker: View {
    @Binding var selectedImage: UIImage?
    @Binding var isLoading: Bool
    let onImageSelected: (UIImage) async -> Void
    
    @State private var showImagePicker = false
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            // Current image or placeholder
            ZStack {
                if let selectedImage = selectedImage {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    ZStack {
                        Circle()
                            .fill(Color(.systemGray6))
                        
                        Image(systemName: "person.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(width: 120, height: 120)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(themeManager.accent.opacity(0.3), lineWidth: 2)
            )
            
            if isLoading {
                ProgressView()
                    .scaleEffect(1.2)
            } else {
                Button {
                    showImagePicker = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "photo")
                        Text("Change Photo".localized)
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(themeManager.accent)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(themeManager.accent.opacity(0.1))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .sheet(isPresented: $showImagePicker) {
            UIImagePicker(sourceType: .photoLibrary) { image in
                Task {
                    await handleImageSelected(image)
                }
            }
        }
    }
    
    private func handleImageSelected(_ image: UIImage) async {
        await MainActor.run {
            selectedImage = image
        }
        await onImageSelected(image)
    }
}

// Simple UIImagePickerController wrapper
struct UIImagePicker: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    let onImageSelected: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: UIImagePicker
        
        init(_ parent: UIImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            picker.dismiss(animated: true)
            
            if let image = info[.originalImage] as? UIImage {
                parent.onImageSelected(image)
            }
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

// Firebase Storage upload helper
class ProfileImageUploader {
    static let shared = ProfileImageUploader()
    private let db = Firestore.firestore()
    
    func uploadProfileImage(_ image: UIImage, userId: String) async throws -> String {
        print("ProfileImageUploader: Original image size: \(image.size)")
        
        // Resize image to max 200x200 first
        let maxSize: CGFloat = 200
        let resizedImage = resizeImage(image, targetSize: maxSize)
        print("ProfileImageUploader: Resized to: \(resizedImage.size)")
        
        // Compress very aggressively (5% quality)
        guard let imageData = resizedImage.jpegData(compressionQuality: 0.05) else {
            throw NSError(domain: "ImageUploadError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])
        }
        
        print("ProfileImageUploader: JPEG data size: \(imageData.count) bytes")
        
        let base64String = imageData.base64EncodedString()
        print("ProfileImageUploader: Base64 size: \(base64String.count) bytes")
        
        // Check size limit (Firestore has 1MB document limit, leave room for other fields)
        guard base64String.count < 500000 else {
            throw NSError(domain: "ImageUploadError", code: -2, userInfo: [NSLocalizedDescriptionKey: "Image too large even after compression"])
        }
        
        // Store in user document
        try await db.collection("users").document(userId).updateData([
            "profilePhotoBase64": base64String,
            "profilePhotoUpdatedAt": Timestamp(date: Date())
        ])
        
        // Return a data URL
        return "data:image/jpeg;base64,\(base64String)"
    }
    
    private func resizeImage(_ image: UIImage, targetSize: CGFloat) -> UIImage {
        let size = image.size
        let ratio = min(targetSize / size.width, targetSize / size.height)
        
        // If image is already smaller, don't upscale
        guard ratio < 1 else { return image }
        
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    
    func deleteOldProfileImage(_ imageUrl: String?) async {
        guard let imageUrl = imageUrl, imageUrl.hasPrefix("data:") else { return }
    }
}
// FORCE RECOMPILE 1776243443
