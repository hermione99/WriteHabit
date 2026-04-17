import SwiftUI
import UIKit

// Font update: Added KoPub, Pretendard, Ridi fonts - 2026-04-14

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
    case koPubBatang = "KoPub Batang"
    case koPubDotum = "KoPub Dotum"
    case pretendard = "Pretendard"
    case ridiBatang = "Ridi Batang"
    
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
        case .koPubBatang: return "KoPub Batang"
        case .koPubDotum: return "KoPub Dotum"
        case .pretendard: return "Pretendard"
        case .ridiBatang: return "Ridi Batang"
        }
    }
    
    var isKoreanFont: Bool {
        switch self {
        case .appleSDGothic, .nanumMyeongjo, .nanumGothic, .koPubBatang, .koPubDotum, .pretendard, .ridiBatang:
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
            // Actual PostScript name: NanumMyeongjo
            if UIFont(name: "NanumMyeongjo", size: 17) != nil {
                return .custom("NanumMyeongjo", size: 17)
            } else {
                return .system(.body, design: .serif)
            }
        case .nanumGothic:
            // Actual PostScript name: NanumGothic
            if UIFont(name: "NanumGothic", size: 17) != nil {
                return .custom("NanumGothic", size: 17)
            } else {
                return .system(.body)
            }
        case .koPubBatang:
            // Actual PostScript name from font file: KoPubWorldBatangPM
            if UIFont(name: "KoPubWorldBatangPM", size: 17) != nil {
                return .custom("KoPubWorldBatangPM", size: 17)
            } else if UIFont(name: "KoPubWorldBatang_Pro Medium", size: 17) != nil {
                return .custom("KoPubWorldBatang_Pro Medium", size: 17)
            } else {
                return .custom("KoPubWorldBatangPM", size: 17)
            }
        case .koPubDotum:
            // Actual PostScript name: KoPubWorldDotumPM
            if UIFont(name: "KoPubWorldDotumPM", size: 17) != nil {
                return .custom("KoPubWorldDotumPM", size: 17)
            } else if UIFont(name: "KoPubWorldDotum_Pro Medium", size: 17) != nil {
                return .custom("KoPubWorldDotum_Pro Medium", size: 17)
            } else {
                return .custom("KoPubWorldDotumPM", size: 17)
            }
        case .pretendard:
            if UIFont(name: "Pretendard-Regular", size: 17) != nil {
                return .custom("Pretendard-Regular", size: 17)
            } else if UIFont(name: "PretendardRegular", size: 17) != nil {
                return .custom("PretendardRegular", size: 17)
            } else {
                return .custom("Pretendard-Regular", size: 17)
            }
        case .ridiBatang:
            // Actual PostScript name: RIDIBatangRegular
            if UIFont(name: "RIDIBatangRegular", size: 17) != nil {
                return .custom("RIDIBatangRegular", size: 17)
            } else if UIFont(name: "RIDIBatang", size: 17) != nil {
                return .custom("RIDIBatang", size: 17)
            } else {
                return .custom("RIDIBatangRegular", size: 17)
            }
        }
    }
    
    func uiFont(size: CGFloat) -> UIFont {
        switch self {
        case .system:
            return UIFont.systemFont(ofSize: size)
        case .serif:
            return UIFont.systemFont(ofSize: size, weight: .regular)
        case .rounded:
            return UIFont.systemFont(ofSize: size, weight: .regular)
        case .monospaced:
            return UIFont.monospacedSystemFont(ofSize: size, weight: .regular)
        case .georgia:
            return UIFont(name: "Georgia", size: size) ?? UIFont.systemFont(ofSize: size)
        case .courier:
            return UIFont(name: "Courier", size: size) ?? UIFont.systemFont(ofSize: size)
        case .appleSDGothic:
            return UIFont(name: "AppleSDGothicNeo-Regular", size: size) ?? UIFont.systemFont(ofSize: size)
        case .nanumMyeongjo:
            // Actual PostScript name: NanumMyeongjo
            return UIFont(name: "NanumMyeongjo", size: size)
                ?? UIFont.systemFont(ofSize: size)
        case .nanumGothic:
            // Actual PostScript name: NanumGothic
            return UIFont(name: "NanumGothic", size: size)
                ?? UIFont.systemFont(ofSize: size)
        case .koPubBatang:
            // Actual PostScript name from font file: KoPubWorldBatangPM (KoPubWorldBatang_Pro Medium)
            return UIFont(name: "KoPubWorldBatangPM", size: size)
                ?? UIFont(name: "KoPubWorldBatang_Pro Medium", size: size)
                ?? UIFont.systemFont(ofSize: size)
        case .koPubDotum:
            // Actual PostScript name: KoPubWorldDotumPM (KoPubWorldDotum_Pro Medium)
            return UIFont(name: "KoPubWorldDotumPM", size: size)
                ?? UIFont(name: "KoPubWorldDotum_Pro Medium", size: size)
                ?? UIFont.systemFont(ofSize: size)
        case .pretendard:
            // This one we had correct
            return UIFont(name: "Pretendard-Regular", size: size)
                ?? UIFont.systemFont(ofSize: size)
        case .ridiBatang:
            // Actual PostScript name: RIDIBatangRegular
            return UIFont(name: "RIDIBatangRegular", size: size)
                ?? UIFont(name: "RIDIBatang", size: size)
                ?? UIFont.systemFont(ofSize: size)
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
        case .koPubBatang:
            // Only Regular variant available, use with bold weight simulation
            return .custom("KoPubBatang-Regular", size: 28)
        case .koPubDotum:
            return .custom("KoPubDotum-Regular", size: 28)
        case .pretendard:
            return .custom("Pretendard-Regular", size: 28)
        case .ridiBatang:
            return .custom("RIDIBatang-Regular", size: 28)
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
        case .koPubBatang:
            // Try multiple possible PostScript names
            if UIFont(name: "KoPubBatang-Regular", size: size) != nil {
                return .custom("KoPubBatang-Regular", size: size)
            } else if UIFont(name: "KoPubBatangRegular", size: size) != nil {
                return .custom("KoPubBatangRegular", size: size)
            } else {
                return .custom("KoPubBatang-Regular", size: size)
            }
        case .koPubDotum:
            if UIFont(name: "KoPubDotum-Regular", size: size) != nil {
                return .custom("KoPubDotum-Regular", size: size)
            } else if UIFont(name: "KoPubDotumRegular", size: size) != nil {
                return .custom("KoPubDotumRegular", size: size)
            } else {
                return .custom("KoPubDotum-Regular", size: size)
            }
        case .pretendard:
            if UIFont(name: "Pretendard-Regular", size: size) != nil {
                return .custom("Pretendard-Regular", size: size)
            } else if UIFont(name: "PretendardRegular", size: size) != nil {
                return .custom("PretendardRegular", size: size)
            } else {
                return .custom("Pretendard-Regular", size: size)
            }
        case .ridiBatang:
            if UIFont(name: "RIDIBatang-Regular", size: size) != nil {
                return .custom("RIDIBatang-Regular", size: size)
            } else if UIFont(name: "RIDIBatangRegular", size: size) != nil {
                return .custom("RIDIBatangRegular", size: size)
            } else {
                return .custom("RIDIBatang-Regular", size: size)
            }
        }
    }
}

class FontManager: ObservableObject {
    static let shared = FontManager()
    @Published var currentFont: AppFont = .system
    @Published var writingFontSize: CGFloat = 17
    @Published var lineSpacing: CGFloat = 4
    
    private let fontKey = "selectedFont"
    private let fontSizeKey = "writingFontSize"
    private let lineSpacingKey = "lineSpacing"
    
    init() {
        if let savedFont = UserDefaults.standard.string(forKey: fontKey),
           let font = AppFont(rawValue: savedFont) {
            currentFont = font
        }
        writingFontSize = UserDefaults.standard.object(forKey: fontSizeKey) as? CGFloat ?? 17
        lineSpacing = UserDefaults.standard.object(forKey: lineSpacingKey) as? CGFloat ?? 4
    }
    
    func setFont(_ font: AppFont) {
        currentFont = font
        UserDefaults.standard.set(font.rawValue, forKey: fontKey)
    }
    
    func setFontSize(_ size: CGFloat) {
        writingFontSize = size
        UserDefaults.standard.set(size, forKey: fontSizeKey)
    }
    
    func setLineSpacing(_ spacing: CGFloat) {
        lineSpacing = spacing
        UserDefaults.standard.set(spacing, forKey: lineSpacingKey)
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
