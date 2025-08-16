//
//  NotificationType.swift
//  Cove
//
//  Created by Assistant on 8/8/25.
//

import Foundation

/// Types of notifications the app understands.
/// Backed by stable identifiers used by the backend and APNs/FCM payloads.
enum NotificationType: String, Equatable {
    case friendRequestReceived = "friend_request_received"
    case friendRequestAccepted = "friend_request_accepted"
    case coveInvite = "cove_invite"
    case coveEventCreated = "cove_event_created"
    /// New RSVP notification when someone RSVPs to your hosted event
    case coveEventRSVP = "cove_event_rsvp"

    /// Parse from loosely-typed input
    static func from(_ any: Any?) -> NotificationType? {
        guard let raw = any as? String else { return nil }
        return NotificationType(rawValue: raw)
    }
} 