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
            if let urlString = url, let url = URL(string: urlString) {
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
