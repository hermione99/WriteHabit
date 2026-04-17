import SwiftUI

struct SlideToWriteButton: View {
    let action: () -> Void
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    
    private let buttonHeight: CGFloat = 56
    private let dragThreshold: CGFloat = 0.75
    
    var body: some View {
        GeometryReader { geometry in
            let maxDrag = geometry.size.width * dragThreshold
            let progress = min(dragOffset / maxDrag, 1.0)
            
            ZStack {
                // Background track
                RoundedRectangle(cornerRadius: buttonHeight / 2)
                    .fill(Color(.systemGray6))
                
                // Progress fill
                HStack {
                    RoundedRectangle(cornerRadius: buttonHeight / 2)
                        .fill(.primary)
                        .frame(width: geometry.size.width * progress)
                    Spacer()
                }
                
                // Text
                Text("Slide to write".localized)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(progress > 0.5 ? .white : .primary)
                    .opacity(1 - progress * 0.3)
                
                // Draggable thumb
                HStack {
                    Circle()
                        .fill(.primary)
                        .frame(width: 48, height: 48)
                        .overlay(
                            Image(systemName: "arrow.right")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                        )
                        .offset(x: dragOffset)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    isDragging = true
                                    dragOffset = max(0, min(value.translation.width, maxDrag))
                                }
                                .onEnded { _ in
                                    isDragging = false
                                    if dragOffset >= maxDrag {
                                        withAnimation(.easeOut(duration: 0.15)) {
                                            dragOffset = geometry.size.width - 52
                                        }
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                            action()
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                                withAnimation {
                                                    dragOffset = 0
                                                }
                                            }
                                        }
                                    } else {
                                        withAnimation(.spring(response: 0.3)) {
                                            dragOffset = 0
                                        }
                                    }
                                }
                        )
                    
                    Spacer()
                }
                .padding(.horizontal, 4)
            }
        }
        .frame(height: buttonHeight)
    }
}

#Preview {
    VStack(spacing: 40) {
        SlideToWriteButton {
            print("Writing started!")
        }
        .padding(.horizontal, 40)
    }
}
