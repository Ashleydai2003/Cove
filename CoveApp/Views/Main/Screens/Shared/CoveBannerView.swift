import SwiftUI
import UIKit

// Uses AlertBannerView for messaging placeholder
struct CoveBannerView: View {
    var onInbox: (() -> Void)? = nil
    var showBookmarkButton: Bool = false
    @EnvironmentObject var appController: AppController
    @State private var showInvites = false

    var body: some View {
        HStack(alignment: .center) {
            Text("cove")
                .font(.LibreBodoniBold(size: 32))
                .foregroundColor(Colors.primaryDark)
            Spacer()
            HStack(spacing: 18) {
                if showBookmarkButton {
                    Button(action: {
                        // placeholder for future bookmark action
                    }) {
                        Image(systemName: "bookmark")
                            .resizable()
                            .frame(width: 20, height: 26)
                            .foregroundColor(Colors.primaryDark)
                    }
                }

                Button(action: {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
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
            }
        }
        .padding(.horizontal, 30)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Colors.background)
        .sheet(isPresented: $showInvites) {
            InboxView()
        }
    }
}

#Preview {
    CoveBannerView()
        .environmentObject(AppController.shared)
}
