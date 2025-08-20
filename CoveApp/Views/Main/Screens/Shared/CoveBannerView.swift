import SwiftUI

// Uses AlertBannerView for messaging placeholder
struct CoveBannerView: View {
    var onInbox: (() -> Void)? = nil
    var onCalendar: (() -> Void)? = nil
    var showCalendarButton: Bool = true
    var showBookmarkButton: Bool = false
    @State private var showInvites = false
    @State private var showCalendar = false

    var body: some View {
        HStack(alignment: .center) {
            Text("cove")
                .font(.LibreBodoniBold(size: 32))
                .foregroundColor(Colors.primaryDark)
            Spacer()
            HStack(spacing: 18) {
                if showCalendarButton {
                    Button(action: {
                        showCalendar = true
                        onCalendar?()
                    }) {
                        Image(systemName: "calendar")
                            .resizable()
                            .frame(width: 26, height: 26)
                            .foregroundColor(Colors.primaryDark)
                    }
                }

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
                    showInvites = true
                    onInbox?()
                }) {
                    Image(systemName: "envelope")
                        .resizable()
                        .frame(width: 28, height: 22)
                        .foregroundColor(Colors.primaryDark)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .background(Colors.background)
        .padding(.horizontal, 30)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .sheet(isPresented: $showInvites) {
            InboxView()
        }
        .sheet(isPresented: $showCalendar) {
            CalendarPopupView()
        }
    }
}

#Preview {
    CoveBannerView()
}
