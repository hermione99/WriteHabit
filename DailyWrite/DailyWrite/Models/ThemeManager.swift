import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case light = "light"
    case dark = "dark"
    case system = "system"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        case .system:
            return "System"
        }
    }
    
    var icon: String {
        switch self {
        case .light:
            return "sun.max.fill"
        case .dark:
            return "moon.fill"
        case .system:
            return "circle.righthalf.filled"
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return nil
        }
    }
}

// MARK: - Accent Colors

enum AppAccentColor: String, CaseIterable, Identifiable {
    case blue = "blue"
    case green = "green"
    case orange = "orange"
    case pink = "pink"
    case purple = "purple"
    case red = "red"
    case teal = "teal"
    case yellow = "yellow"
    case mint = "mint"
    case indigo = "indigo"
    case cyan = "cyan"
    case lime = "lime"
    case brown = "brown"
    case coral = "coral"
    case lavender = "lavender"
    case rose = "rose"
    case gold = "gold"
    case slate = "slate"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .blue: return "Blue"
        case .green: return "Green"
        case .orange: return "Orange"
        case .pink: return "Pink"
        case .purple: return "Purple"
        case .red: return "Red"
        case .teal: return "Teal"
        case .yellow: return "Yellow"
        case .mint: return "Mint"
        case .indigo: return "Indigo"
        case .cyan: return "Cyan"
        case .lime: return "Lime"
        case .brown: return "Brown"
        case .coral: return "Coral"
        case .lavender: return "Lavender"
        case .rose: return "Rose"
        case .gold: return "Gold"
        case .slate: return "Slate"
        }
    }
    
    var color: Color {
        switch self {
        case .blue: return .blue
        case .green: return Color(red: 0.2, green: 0.7, blue: 0.3)  // Deep forest green
        case .orange: return .orange
        case .pink: return .pink
        case .purple: return .purple
        case .red: return .red
        case .teal: return .teal
        case .yellow: return .yellow
        case .mint: return .mint
        case .indigo: return .indigo
        case .cyan: return Color(red: 0.0, green: 0.8, blue: 1.0)
        case .lime: return Color(red: 0.6, green: 1.0, blue: 0.2)
        case .brown: return Color(red: 0.6, green: 0.4, blue: 0.2)
        case .coral: return Color(red: 1.0, green: 0.5, blue: 0.4)
        case .lavender: return Color(red: 0.8, green: 0.7, blue: 1.0)
        case .rose: return Color(red: 1.0, green: 0.3, blue: 0.5)
        case .gold: return Color(red: 1.0, green: 0.8, blue: 0.0)
        case .slate: return Color(red: 0.4, green: 0.5, blue: 0.6)
        }
    }
    
    var swiftUIColor: Color {
        color
    }
}

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    @Published var currentTheme: AppTheme = .system
    @Published var accentColor: AppAccentColor = .blue
    
    private let themeKey = "appTheme"
    private let accentColorKey = "appAccentColor"
    
    init() {
        if let savedTheme = UserDefaults.standard.string(forKey: themeKey),
           let theme = AppTheme(rawValue: savedTheme) {
            currentTheme = theme
        }
        
        if let savedAccent = UserDefaults.standard.string(forKey: accentColorKey),
           let accent = AppAccentColor(rawValue: savedAccent) {
            accentColor = accent
        }
    }
    
    func setTheme(_ theme: AppTheme) {
        currentTheme = theme
        UserDefaults.standard.set(theme.rawValue, forKey: themeKey)
    }
    
    func setAccentColor(_ color: AppAccentColor) {
        accentColor = color
        UserDefaults.standard.set(color.rawValue, forKey: accentColorKey)
    }
    
    // Convenience accessor for accent color
    var accent: Color {
        accentColor.color
    }
}

// MARK: - Theme Colors

struct ThemeColors {
    static func paperBackground(for colorScheme: ColorScheme) -> Color {
        switch colorScheme {
        case .dark:
            return Color(red: 0.12, green: 0.12, blue: 0.14)
        default:
            return Color(red: 0.98, green: 0.96, blue: 0.94)
        }
    }
    
    static func paperLines(for colorScheme: ColorScheme) -> Color {
        switch colorScheme {
        case .dark:
            return Color.white.opacity(0.05)
        default:
            return Color.black.opacity(0.02)
        }
    }
    
    static func textPrimary(for colorScheme: ColorScheme) -> Color {
        switch colorScheme {
        case .dark:
            return Color(red: 0.92, green: 0.92, blue: 0.94)
        default:
            return .primary
        }
    }
    
    static func textSecondary(for colorScheme: ColorScheme) -> Color {
        switch colorScheme {
        case .dark:
            return Color(red: 0.6, green: 0.6, blue: 0.65)
        default:
            return .secondary
        }
    }
    
    static func cardBackground(for colorScheme: ColorScheme) -> Color {
        switch colorScheme {
        case .dark:
            return Color(red: 0.18, green: 0.18, blue: 0.20)
        default:
            return Color(.systemBackground)
        }
    }
    
    static func accentColor(for colorScheme: ColorScheme) -> Color {
        // Keep the accent color consistent
        return .blue
    }
}
