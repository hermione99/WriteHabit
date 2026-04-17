import SwiftUI

struct PenIllustration: View {
    var body: some View {
        Canvas { context, size in
            // Pen body
            let penPath = Path { path in
                // Start from top
                path.move(to: CGPoint(x: size.width * 0.5, y: size.height * 0.1))
                // Line down
                path.addLine(to: CGPoint(x: size.width * 0.5, y: size.height * 0.7))
                // Pen tip
                path.addLine(to: CGPoint(x: size.width * 0.35, y: size.height * 0.85))
                path.addLine(to: CGPoint(x: size.width * 0.5, y: size.height * 0.75))
                path.addLine(to: CGPoint(x: size.width * 0.65, y: size.height * 0.85))
                path.addLine(to: CGPoint(x: size.width * 0.5, y: size.height * 0.7))
                // Close
                path.closeSubpath()
                
                // Pen clip
                path.move(to: CGPoint(x: size.width * 0.5, y: size.height * 0.25))
                path.addLine(to: CGPoint(x: size.width * 0.65, y: size.height * 0.2))
                path.addLine(to: CGPoint(x: size.width * 0.65, y: size.height * 0.35))
                path.addLine(to: CGPoint(x: size.width * 0.5, y: size.height * 0.4))
                path.closeSubpath()
            }
            
            // Draw pen outline
            context.stroke(
                penPath,
                with: .color(.primary),
                lineWidth: 2
            )
            
            // Draw ink dot
            let dotPath = Path { path in
                path.addEllipse(in: CGRect(
                    x: size.width * 0.25,
                    y: size.height * 0.88,
                    width: size.width * 0.12,
                    height: size.width * 0.08
                ))
            }
            context.fill(dotPath, with: .color(.primary))
            
            // Draw some abstract lines (writing motion)
            let linePath = Path { path in
                path.move(to: CGPoint(x: size.width * 0.7, y: size.height * 0.5))
                path.addCurve(
                    to: CGPoint(x: size.width * 0.9, y: size.height * 0.6),
                    control1: CGPoint(x: size.width * 0.75, y: size.height * 0.45),
                    control2: CGPoint(x: size.width * 0.85, y: size.height * 0.55)
                )
            }
            context.stroke(linePath, with: .color(.primary.opacity(0.3)), lineWidth: 1.5)
            
            // Another line
            let linePath2 = Path { path in
                path.move(to: CGPoint(x: size.width * 0.1, y: size.height * 0.3))
                path.addCurve(
                    to: CGPoint(x: size.width * 0.3, y: size.height * 0.4),
                    control1: CGPoint(x: size.width * 0.15, y: size.height * 0.25),
                    control2: CGPoint(x: size.width * 0.25, y: size.height * 0.35)
                )
            }
            context.stroke(linePath2, with: .color(.primary.opacity(0.2)), lineWidth: 1)
        }
        .frame(width: 120, height: 150)
    }
}

// Alternative: Minimal line pen
struct MinimalPenIcon: View {
    var body: some View {
        Image(systemName: "pencil.line")
            .font(.system(size: 80, weight: .thin))
            .foregroundStyle(.primary.opacity(0.15))
    }
}

// Abstract writing marks
struct WritingMarks: View {
    var body: some View {
        Canvas { context, size in
            // Scribble lines
            for i in 0..<5 {
                let y = size.height * (0.2 + Double(i) * 0.15)
                let path = Path { path in
                    path.move(to: CGPoint(x: size.width * 0.1, y: y))
                    path.addCurve(
                        to: CGPoint(x: size.width * 0.9, y: y + CGFloat.random(in: -10...10)),
                        control1: CGPoint(x: size.width * 0.3, y: y + CGFloat.random(in: -20...20)),
                        control2: CGPoint(x: size.width * 0.7, y: y + CGFloat.random(in: -20...20))
                    )
                }
                context.stroke(
                    path,
                    with: .color(.primary.opacity(0.1 + Double(i) * 0.05)),
                    lineWidth: CGFloat(2 + i)
                )
            }
        }
        .frame(width: 200, height: 120)
    }
}

#Preview {
    VStack(spacing: 40) {
        PenIllustration()
        MinimalPenIcon()
        WritingMarks()
    }
    .padding()
}
