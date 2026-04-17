import SwiftUI

// Temporary view to test font loading
struct FontTestView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Testing Fonts")
                .font(.title)
            
            Group {
                Text("System Font")
                    .font(.system(size: 17))
                
                Text("KoPub Batang (UIFont)")
                    .font(Font(UIFont(name: "KoPubBatang-Regular", size: 17) ?? UIFont.systemFont(ofSize: 17)))
                
                Text("KoPub Batang (.custom)")
                    .font(.custom("KoPubBatang-Regular", size: 17))
                
                Text("Pretendard")
                    .font(.custom("Pretendard-Regular", size: 17))
                
                Text("RIDI Batang")
                    .font(.custom("RIDIBatang-Regular", size: 17))
                
                Text("KoPub Dotum")
                    .font(.custom("KoPubDotum-Regular", size: 17))
            }
        }
        .padding()
    }
}

#Preview {
    FontTestView()
}
