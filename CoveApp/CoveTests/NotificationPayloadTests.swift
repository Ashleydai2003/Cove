//
//  NotificationPayloadTests.swift
//  CoveTests
//
//  Created by Assistant on 8/8/25.
//

import Testing
@testable import Cove

struct NotificationPayloadTests {

    @Test func parsesAPNSLikeUserInfo() throws {
        let userInfo: [AnyHashable: Any] = [
            "aps": [
                "alert": [
                    "title": "New <b>Message</b>",
                    "body": "Alex: Hello\n\nWorld"
                ]
            ],
            "deeplink": "cove://threads/abc123",
            "in_app_only": true
        ]
        let payload = NotificationPayload(userInfo: userInfo)
        #expect(payload != nil)
        #expect(payload?.title == "New Message")
        #expect(payload?.body == "Alex: Hello World")
        #expect(payload?.deepLink?.absoluteString == "cove://threads/abc123")
        #expect(payload?.inAppOnly == true)
    }

    @Test func rejectsEmpty() throws {
        let payload = NotificationPayload(userInfo: [:])
        #expect(payload == nil)
    }
} 