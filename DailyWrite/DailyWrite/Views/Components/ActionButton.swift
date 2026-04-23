import SwiftUI

struct ActionButton: View {
    let icon: String
    let text: String
    let backgroundColor: Color
    let textColor: Color
    let borderColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                Text(text)
                    .font(.system(size: 12, weight: .medium, design: .serif))
                    .tracking(0.5)
            }
            .foregroundColor(textColor)
            .frame(width: 120, height: 40)
            .background(backgroundColor)
            .overlay(
                Rectangle()
                    .stroke(borderColor, lineWidth: 1)
            )
        }
    }
}
