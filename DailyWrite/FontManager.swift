import SwiftUI
import SwiftUI

enum AppFont: String, CaseIterable, Identifiable {
    case system = "System"
    case serif = "Serif"
    case rounded = "Rounded"
    case monospaced = "Monospaced"
    case georgia = "Georgia"
    case courier = "Courier"
    
    // Korean fonts
    case appleSDGothic = "Apple SD Gothic Neo"
    case nanumMyeongjo = "Nanum Myeongjo"
    case nanumGothic = "Nanum Gothic"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .system: return "System"
        case .serif: return "Serif"
        case .rounded: return "Rounded"
        case .monospaced: return "Monospaced"
        case .georgia: return "Georgia"
        case .courier: return "Courier"
        case .appleSDGothic: return "Apple SD Gothic Neo"
        case .nanumMyeongjo: return "Nanum Myeongjo"
        case .nanumGothic: return "Nanum Gothic"
        }
    }
    
    var isKoreanFont: Bool {
        switch self {
        case .appleSDGothic, .nanumMyeongjo, .nanumGothic:
            return true
        default:
            return false
        }
    }
    
    var font: Font {
        switch self {
        case .system:
            return .body
        case .serif:
            return .system(.body, design: .serif)
        case .rounded:
            return .system(.body, design: .rounded)
        case .monospaced:
            return .system(.body, design: .monospaced)
        case .georgia:
            return .custom("Georgia", size: 17)
        case .courier:
            return .custom("Courier", size: 17)
        case .appleSDGothic:
            return .custom("AppleSDGothicNeo-Regular", size: 17)
        case .nanumMyeongjo:
            return .custom("NanumMyeongjo", size: 17)
        case .nanumGothic:
            return .custom("NanumGothic", size: 17)
        }
    }
    
    var largeFont: Font {
        switch self {
        case .system:
            return .title
        case .serif:
            return .system(.title, design: .serif)
        case .rounded:
            return .system(.title, design: .rounded)
        case .monospaced:
            return .system(.title, design: .monospaced)
        case .georgia:
            return .custom("Georgia", size: 28)
        case .courier:
            return .custom("Courier", size: 28)
        case .appleSDGothic:
            return .custom("AppleSDGothicNeo-Bold", size: 28)
        case .nanumMyeongjo:
            return .custom("NanumMyeongjo-Bold", size: 28)
        case .nanumGothic:
            return .custom("NanumGothicBold", size: 28)
        }
    }
    
    func font(size: CGFloat) -> Font {
        switch self {
        case .system:
            return .system(size: size)
        case .serif:
            return .system(size: size, design: .serif)
        case .rounded:
            return .system(size: size, design: .rounded)
        case .monospaced:
            return .system(size: size, design: .monospaced)
        case .georgia:
            return .custom("Georgia", size: size)
        case .courier:
            return .custom("Courier", size: size)
        case .appleSDGothic:
            return .custom("AppleSDGothicNeo-Regular", size: size)
        case .nanumMyeongjo:
            return .custom("NanumMyeongjo", size: size)
        case .nanumGothic:
            return .custom("NanumGothic", size: size)
        }
    }
}

class FontManager: ObservableObject {
    static let shared = FontManager()
    @Published var currentFont: AppFont = .system
    @Published var writingFontSize: CGFloat = 17
    
    private let fontKey = "selectedFont"
    private let fontSizeKey = "writingFontSize"
    
    init() {
        if let savedFont = UserDefaults.standard.string(forKey: fontKey),
           let font = AppFont(rawValue: savedFont) {
            currentFont = font
        }
        writingFontSize = UserDefaults.standard.object(forKey: fontSizeKey) as? CGFloat ?? 17
    }
    
    func setFont(_ font: AppFont) {
        currentFont = font
        UserDefaults.standard.set(font.rawValue, forKey: fontKey)
    }
    
    func setFontSize(_ size: CGFloat) {
        writingFontSize = size
        UserDefaults.standard.set(size, forKey: fontSizeKey)
    }
}

extension View {
    func appFont(_ font: AppFont, size: CGFloat? = nil) -> some View {
        if let size = size {
            return self.font(font.font(size: size))
        } else {
            return self.font(font.font)
        }
    }
}
