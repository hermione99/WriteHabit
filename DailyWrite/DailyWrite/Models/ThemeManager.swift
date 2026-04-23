import SwiftUI

// MARK: - Accent Color (Fixed to Indigo Rain)

enum AppAccentColor: String, CaseIterable, Identifiable {
    case indigoRain = "indigoRain"
    
    var id: String { rawValue }
    
    var displayName: String { "Indigo Rain" }
    
    var color: Color {
        Color(hex: "0D244D")
    }
    
    var swiftUIColor: Color {
        color
    }
}

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    // Fixed to light theme only
    var currentTheme: AppTheme { .light }
    
    // Fixed to Indigo Rain accent
    var accentColor: AppAccentColor { .indigoRain }
    
    // Convenience accessor for accent color
    var accent: Color {
        Color(hex: "0D244D")
    }
}

// MARK: - Theme (Light only)

enum AppTheme: String {
    case light = "light"
    
    var colorScheme: ColorScheme? {
        .light
    }
}

// MARK: - Theme Colors (Light theme only)

struct ThemeColors {
    static func paperBackground(for colorScheme: ColorScheme) -> Color {
        Color(red: 0.98, green: 0.96, blue: 0.94) // Cream
    }
    
    static func paperLines(for colorScheme: ColorScheme) -> Color {
        Color.black.opacity(0.02)
    }
    
    static func textPrimary(for colorScheme: ColorScheme) -> Color {
        .primary
    }
    
    static func textSecondary(for colorScheme: ColorScheme) -> Color {
        .secondary
    }
    
    static func cardBackground(for colorScheme: ColorScheme) -> Color {
        Color(.systemBackground)
    }
    
    static func accentColor(for colorScheme: ColorScheme) -> Color {
        Color(hex: "0D244D") // Indigo Rain
    }
}
