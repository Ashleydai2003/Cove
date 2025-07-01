import SwiftUI

struct CoveBannerView: View {
    var onInbox: (() -> Void)? = nil
    var onPaperPlane: (() -> Void)? = nil
    
    var body: some View {
        HStack(alignment: .center) {
            Text("cove")
                .font(.LibreBodoniBold(size: 32))
                .foregroundColor(Colors.primaryDark)
            Spacer()
            HStack(spacing: 18) {
                Button(action: { onInbox?() }) {
                    Image(systemName: "envelope")
                        .resizable()
                        .frame(width: 28, height: 22)
                        .foregroundColor(Colors.primaryDark)
                }
                Button(action: { onPaperPlane?() }) {
                    Image(systemName: "paperplane")
                        .resizable()
                        .frame(width: 26, height: 26)
                        .foregroundColor(Colors.primaryDark)
                }
            }
        }
        .padding(.horizontal, 30)
        .padding(.top, 24)
        .padding(.bottom, 8)
    }
}

#Preview {
    CoveBannerView()
} 