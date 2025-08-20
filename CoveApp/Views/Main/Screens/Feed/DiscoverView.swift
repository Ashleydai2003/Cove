//
//  DiscoverView.swift
//  Cove
//

import SwiftUI

struct DiscoverView: View {
	var body: some View {
		NavigationStack {
			VStack(spacing: 0) {
				// Header consistent with other tabs
				CoveBannerView(onInbox: {
					AppController.shared.shouldAutoShowInbox = true
				}, onCalendar: nil, showCalendarButton: false, showBookmarkButton: true)

				ZStack {
					Colors.background
						.ignoresSafeArea()

					VStack(spacing: 12) {
						Text("Discover is coming soon!")
							.font(.LibreBodoniSemiBold(size: 24))
							.foregroundColor(Colors.primaryDark)
					}
					.frame(maxWidth: .infinity, maxHeight: .infinity)
				}
			}
		}
		.navigationBarBackButtonHidden()
	}
}

#Preview {
	DiscoverView()
		.environmentObject(AppController.shared)
}


