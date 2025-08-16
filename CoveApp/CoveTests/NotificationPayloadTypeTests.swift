//
//  NotificationPayloadTypeTests.swift
//  CoveTests
//
//  Created by Assistant on 8/8/25.
//

import Testing
@testable import Cove

struct NotificationPayloadTypeTests {

    @Test func parsesTypeAndIds() throws {
        let userInfo: [AnyHashable: Any] = [
            "aps": ["alert": ["title": "New invite", "body": "You were invited"]],
            "type": "cove_invite",
            "actor_user_id": "user_123",
            "cove_id": "cove_456"
        ]
        let payload = NotificationPayload(userInfo: userInfo)
        #expect(payload?.type == .coveInvite)
        #expect(payload?.actorUserId == "user_123")
        #expect(payload?.coveId == "cove_456")
        #expect(payload?.eventId == nil)
    }
} 