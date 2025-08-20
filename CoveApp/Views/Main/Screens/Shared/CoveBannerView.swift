import SwiftUI

// Uses AlertBannerView for messaging placeholder
struct CoveBannerView: View {
    var onInbox: (() -> Void)? = nil
    var onPaperPlane: (() -> Void)? = nil
    @State private var showInvites = false
    @State private var showMessageBanner = false
    @EnvironmentObject var appController: AppController

    var body: some View {
        HStack(alignment: .center) {
            Text("cove")
                .font(.LibreBodoniBold(size: 32))
                .foregroundColor(Colors.primaryDark)
            Spacer()
            HStack(spacing: 18) {
                Button(action: {
                    showInvites = true
                    onInbox?()
                }) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "envelope")
                            .resizable()
                            .frame(width: 28, height: 22)
                            .foregroundColor(Colors.primaryDark)
                        if appController.inboxViewModel.hasUnopenedInvites {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                                .offset(x: 6, y: -6)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())

                Button(action: {
                    onPaperPlane?()
                    withAnimation { showMessageBanner = true }
                }) {
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
        .sheet(isPresented: $showInvites) {
            InboxView()
        }
        .overlay(
            AlertBannerView(message: "direct messaging coming soon!", isVisible: $showMessageBanner)
                .animation(.easeInOut, value: showMessageBanner)
        )
    }
}

#Preview {
    CoveBannerView()
        .environmentObject(AppController.shared)
}
