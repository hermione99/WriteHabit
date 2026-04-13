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

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    @Published var currentTheme: AppTheme = .system
    
    private let themeKey = "appTheme"
    
    init() {
        if let savedTheme = UserDefaults.standard.string(forKey: themeKey),
           let theme = AppTheme(rawValue: savedTheme) {
            currentTheme = theme
        }
    }
    
    func setTheme(_ theme: AppTheme) {
        currentTheme = theme
        UserDefaults.standard.set(theme.rawValue, forKey: themeKey)
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
