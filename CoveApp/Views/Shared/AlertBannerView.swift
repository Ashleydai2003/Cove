import SwiftUI

/// AlertBannerView: A lightweight banner that slides from the top to show brief messages (à la Instagram / Snapchat style).
/// Usage: Bind `isVisible` to a @State Bool. Set it true to show. It auto-dismisses after `duration` seconds unless `isPersistent`.
struct AlertBannerView: View {
    enum Style {
        case normal, warning, error
        var background: Color {
            switch self {
            case .normal: return Colors.primaryDark
            case .warning: return Color.orange
            case .error:   return Color.red
            }
        }
    }
    let message: String
    var style: Style = .normal
    @Binding var isVisible: Bool
    var duration: TimeInterval = 2.0
    var isPersistent: Bool = false

    var body: some View {
        if isVisible {
            VStack {
                Text(message)
                    .font(.LibreBodoni(size: 14))
                    .foregroundColor(.white)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 24)
                    .frame(maxWidth: .infinity)
                    .background(style.background)
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                    .onTapGesture { withAnimation { isVisible = false } }
                Spacer()
            }
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.25), value: isVisible)
            .onAppear {
                if !isPersistent {
                    DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                        withAnimation { isVisible = false }
                    }
                }
            }
        }
    }
}
