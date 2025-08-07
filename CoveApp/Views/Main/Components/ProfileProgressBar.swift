import SwiftUI

struct ProfileProgressBar: View {
    let progress: Double // 0.0 to 1.0
    
    var body: some View {
        VStack(spacing: 8) {
            // Progress bar container
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Colors.primaryDark.opacity(0.1))
                        .frame(height: 8)
                    
                    // Progress fill
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Colors.primaryDark)
                        .frame(width: geometry.size.width * progress, height: 8)
                        .animation(.easeInOut(duration: 0.3), value: progress)
                }
            }
            .frame(height: 8)
            
            // Progress text
            Text("\(Int(progress * 100))% complete")
                .font(.LeagueSpartan(size: 12))
                .foregroundColor(Colors.k6F6F73)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

#Preview {
    VStack(spacing: 20) {
        ProfileProgressBar(progress: 0.0)
        ProfileProgressBar(progress: 0.25)
        ProfileProgressBar(progress: 0.5)
        ProfileProgressBar(progress: 0.75)
        ProfileProgressBar(progress: 1.0)
    }
    .padding()
} 