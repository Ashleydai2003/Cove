//
//  NotificationPayload.swift
//  Cove
//
//  Created by Assistant on 8/8/25.
//

import Foundation
import UserNotifications

/// A validated, sanitized representation of a push notification payload.
/// Use this type instead of reading raw `userInfo` to avoid unsafe input making it to UI.
struct NotificationPayload: Equatable {
    /// Title to display in app
    let title: String
    /// Body/message to display in app
    let body: String
    /// Optional deep link to navigate when tapped
    let deepLink: URL?
    /// Optional category identifier
    let category: String?
    /// Whether we should only show an in-app banner (and suppress system banner) when foreground
    let inAppOnly: Bool

    /// Designated initializer used internally after validation
    private init(title: String, body: String, deepLink: URL?, category: String?, inAppOnly: Bool) {
        self.title = title
        self.body = body
        self.deepLink = deepLink
        self.category = category
        self.inAppOnly = inAppOnly
    }

    /// Maximum lengths to defend against overly large payloads
    private static let maxTitleLength = 120
    private static let maxBodyLength = 500

    /// Create a payload by validating and sanitizing a `UNNotificationContent`
    init?(content: UNNotificationContent) {
        // Prefer APS alert structure first
        let userInfo = content.userInfo
        if let parsed = NotificationPayload.parse(from: userInfo) {
            self = parsed
            return
        }
        // Fallback to content title/body if userInfo is not present/usable
        let rawTitle = content.title
        let rawBody = content.body
        guard !rawTitle.isEmpty || !rawBody.isEmpty else { return nil }
        self.title = NotificationPayload.sanitize(rawTitle, maxLen: Self.maxTitleLength)
        self.body = NotificationPayload.sanitize(rawBody, maxLen: Self.maxBodyLength)
        self.deepLink = nil
        self.category = content.categoryIdentifier.isEmpty ? nil : content.categoryIdentifier
        self.inAppOnly = false
    }

    /// Create a payload by validating and sanitizing a `userInfo` dictionary (APNS/FCM)
    init?(userInfo: [AnyHashable: Any]) {
        guard let parsed = NotificationPayload.parse(from: userInfo) else { return nil }
        self = parsed
    }
}

// MARK: - Parsing & Sanitization

extension NotificationPayload {
    /// Attempts to parse common APNS/FCM structures from raw `userInfo`
    static func parse(from userInfo: [AnyHashable: Any]) -> NotificationPayload? {
        // Helper to pull nested APS.alert structure
        let aps = userInfo["aps"] as? [String: Any]
        let alert = aps?["alert"]

        let rawTitle: String? = {
            if let alertStr = alert as? String { return alertStr }
            if let alertDict = alert as? [String: Any] {
                if let t = alertDict["title"] as? String { return t }
                if let locKey = alertDict["title-loc-key"] as? String { return locKey }
            }
            if let directTitle = userInfo["title"] as? String { return directTitle }
            return nil
        }()

        let rawBody: String? = {
            if alert is String { return nil }
            if let alertDict = alert as? [String: Any] {
                if let b = alertDict["body"] as? String { return b }
                if let locKey = alertDict["loc-key"] as? String { return locKey }
            }
            if let directBody = userInfo["body"] as? String { return directBody }
            return nil
        }()

        guard let titleCandidate = rawTitle ?? rawBody, // allow body-only notifications
              !(titleCandidate.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) else { return nil }

        let title = sanitize(rawTitle ?? "", maxLen: maxTitleLength)
        let body = sanitize(rawBody ?? "", maxLen: maxBodyLength)

        let deepLink: URL? = {
            if let linkStr = userInfo["deeplink"] as? String, let url = URL(string: linkStr), url.scheme?.hasPrefix("http") == true || url.scheme == "cove" {
                return url
            }
            if let linkStr = userInfo["link"] as? String, let url = URL(string: linkStr), url.scheme?.hasPrefix("http") == true || url.scheme == "cove" {
                return url
            }
            return nil
        }()

        let category = (userInfo["category"] as? String).flatMap { sanitize($0, maxLen: 64) }.flatMap { $0.isEmpty ? nil : $0 }
        let inAppOnlyFlag = (userInfo["in_app_only"] as? Bool)
            ?? Bool((userInfo["in_app_only"] as? String) ?? "false")
            ?? false

        return NotificationPayload(
            title: title,
            body: body,
            deepLink: deepLink,
            category: category,
            inAppOnly: inAppOnlyFlag
        )
    }

    /// Plain-string sanitization to remove control characters and simple tags.
    /// Not a full HTML sanitizer, but enough to protect typical banners.
    static func sanitize(_ value: String, maxLen: Int) -> String {
        if value.isEmpty { return "" }
        // Strip control characters
        let noControls = value.unicodeScalars.filter { $0.value >= 0x20 && $0.value != 0x7F }
        var cleaned = String(String.UnicodeScalarView(noControls))
        // Very simple tag stripper to avoid rendering surprises
        cleaned = cleaned.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        // Collapse whitespace
        cleaned = cleaned.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        // Trim and limit length
        if cleaned.count > maxLen {
            let idx = cleaned.index(cleaned.startIndex, offsetBy: maxLen)
            cleaned = String(cleaned[..<idx]) + "…"
        }
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
} 