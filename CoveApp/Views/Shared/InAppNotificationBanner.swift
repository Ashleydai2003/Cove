//
//  InAppNotificationBanner.swift
//  Cove
//
//  Created by Assistant on 8/8/25.
//

import SwiftUI

struct InAppNotificationBanner: View {
    let payload: NotificationPayload
    var onTap: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "bell.fill")
                    .foregroundStyle(.white)
                    .font(.system(size: 16, weight: .semibold))
                VStack(alignment: .leading, spacing: 4) {
                    if !payload.title.isEmpty {
                        Text(payload.title)
                            .font(.headline)
                            .foregroundStyle(.white)
                            .lineLimit(2)
                    }
                    if !payload.body.isEmpty {
                        Text(payload.body)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.92))
                            .lineLimit(2)
                    }
                }
                Spacer(minLength: 8)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(.black.opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 8)
            .padding(.horizontal, 12)
            .padding(.top, 8)
            Spacer(minLength: 0)
        }
        .contentShape(Rectangle())
        .onTapGesture { onTap?() }
        .transition(.move(edge: .top).combined(with: .opacity))
        .accessibilityLabel("In-app notification")
        .accessibilityHint("Double tap to open")
    }
}

#Preview {
    InAppNotificationBanner(payload: NotificationPayload(userInfo: [
        "title": "New Message",
        "body": "Alex: Let's grab coffee tomorrow at 3?",
        "deeplink": "cove://threads/123"
    ])!)
} 