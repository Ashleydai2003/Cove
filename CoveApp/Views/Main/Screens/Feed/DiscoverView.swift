//
//  DiscoverView.swift
//  Cove
//

import SwiftUI

struct DiscoverView: View {
	var body: some View {
		NavigationStack {
			ZStack {
				Colors.background.ignoresSafeArea()

				VStack(spacing: 0) {
					// Minimal header with only bookmark icon at top-right
					HStack {
						Spacer()
						Button(action: {
							// placeholder for future bookmark action
						}) {
							Image(systemName: "bookmark")
								.resizable()
								.frame(width: 20, height: 26)
								.foregroundColor(Colors.primaryDark)
						}
						.padding(.horizontal, 30)
						.padding(.top, 12)
						.padding(.bottom, 8)
					}

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


