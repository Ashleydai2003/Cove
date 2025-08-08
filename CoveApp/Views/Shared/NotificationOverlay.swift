//
//  NotificationOverlay.swift
//  Cove
//
//  Created by Assistant on 8/8/25.
//

import SwiftUI

struct NotificationOverlay: View {
    @StateObject private var manager = NotificationManager.shared
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(spacing: 0) {
            if let payload = manager.current {
                InAppNotificationBanner(payload: payload) {
                    // Tap: navigate if deep link provided
                    if let url = payload.deepLink {
                        openURL(url)
                    }
                    manager.dismiss()
                }
                .zIndex(10)
            }
            Spacer(minLength: 0)
        }
        .allowsHitTesting(manager.current != nil)
        .animation(.spring(response: 0.35, dampingFraction: 0.86, blendDuration: 0.2), value: manager.current?.title)
    }
}

#Preview {
    ZStack {
        Color.blue.ignoresSafeArea()
        NotificationOverlay()
    }
} 