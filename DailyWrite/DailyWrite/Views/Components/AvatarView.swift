import SwiftUI

struct AvatarView: View {
    let url: String?
    let size: CGFloat
    let userId: String
    
    init(url: String?, size: CGFloat = 40, userId: String = "") {
        self.url = url
        self.size = size
        self.userId = userId
    }
    
    var body: some View {
        Group {
            if let urlString = url {
                // Check if it's a base64 data URL
                if urlString.hasPrefix("data:image") {
                    if let image = loadBase64Image(from: urlString) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Text("BASE64 FAIL")
                            .font(.caption)
                        placeholder
                    }
                } else if let url = URL(string: urlString) {
                    // Regular URL
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            placeholder
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .failure:
                            placeholder
                        @unknown default:
                            placeholder
                        }
                    }
                } else {
                    placeholder
                }
            } else {
                placeholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
    
    private var placeholder: some View {
        ZStack {
            Circle()
                .fill(Color(.systemGray5))
            
            Image(systemName: "person.fill")
                .font(.system(size: size * 0.4))
                .foregroundStyle(.secondary)
        }
    }
    
    private func loadBase64Image(from dataUrl: String) -> UIImage? {
        print("AvatarView: Loading base64 image, url prefix: \(dataUrl.prefix(50))")
        // Extract base64 data from data URL
        guard let commaIndex = dataUrl.firstIndex(of: ",") else { 
            print("AvatarView: No comma found in data URL")
            return nil 
        }
        let base64String = String(dataUrl[dataUrl.index(after: commaIndex)...])
        print("AvatarView: Base64 string length: \(base64String.count)")
        
        guard let data = Data(base64Encoded: base64String) else {
            print("AvatarView: Failed to decode base64 to Data")
            return nil
        }
        print("AvatarView: Data size: \(data.count) bytes")
        
        guard let image = UIImage(data: data) else {
            print("AvatarView: Failed to create UIImage from Data")
            return nil
        }
        print("AvatarView: Successfully created UIImage")
        
        return image
    }
}

// Initial avatar with user's initials
struct InitialAvatarView: View {
    let name: String
    let size: CGFloat
    let backgroundColor: Color
    
    init(name: String, size: CGFloat = 40, backgroundColor: Color = .blue) {
        self.name = name
        self.size = size
        self.backgroundColor = backgroundColor
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(backgroundColor.opacity(0.2))
            
            Text(initials)
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundStyle(backgroundColor)
        }
        .frame(width: size, height: size)
    }
    
    private var initials: String {
        let components = name.split(separator: " ")
        if components.count > 1 {
            return String(components[0].prefix(1) + components[1].prefix(1)).uppercased()
        } else {
            return String(name.prefix(2)).uppercased()
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        AvatarView(url: nil, size: 40, userId: "test")
        InitialAvatarView(name: "John Doe", size: 40, backgroundColor: .blue)
        InitialAvatarView(name: "Alice", size: 60, backgroundColor: .green)
    }
}
