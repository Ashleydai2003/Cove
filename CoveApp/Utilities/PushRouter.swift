import Foundation
import UIKit
import FirebaseAuth

struct PushPayload: Decodable {
	let type: String?
	let deepLink: String?
	let eventId: String?
	let coveId: String?
	let postId: String?
	let senderId: String?
}

enum PushRouter {
	static func route(from userInfo: [AnyHashable: Any], actionIdentifier: String?) {
		let json = try? JSONSerialization.data(withJSONObject: userInfo, options: [])
		let payload = (json.flatMap { try? JSONDecoder().decode(PushPayload.self, from: $0) }) ?? PushPayload(type: nil, deepLink: nil, eventId: nil, coveId: nil, postId: nil, senderId: nil)
		
		if let deep = payload.deepLink, let url = URL(string: deep) {
			DispatchQueue.main.async { UIApplication.shared.open(url) }
		}
		
		// Action buttons (e.g., RSVP) handled above via RSVPService
		if actionIdentifier == NotificationActionIDs.rsvpYes, let id = payload.eventId {
			Task { await RSVPService.update(eventId: id, status: "GOING") }
			return
		}
		if actionIdentifier == NotificationActionIDs.rsvpNo, let id = payload.eventId {
			Task { await RSVPService.update(eventId: id, status: "NOT_GOING") }
			return
		}
		
		// Deep link by type
		switch payload.type {
		case "event_created", "event_rsvp":
			if let eventId = payload.eventId {
				NotificationCenter.default.post(name: .navigateToEvent, object: nil, userInfo: ["eventId": eventId])
			}
		case "post_created":
			if let postId = payload.postId { // if your app navigates by postId, otherwise use event-like routing
				NotificationCenter.default.post(name: .navigateToPost, object: nil, userInfo: ["postId": postId])
			} else if let coveId = payload.coveId {
				NotificationCenter.default.post(name: .navigateToCove, object: nil, userInfo: ["coveId": coveId])
			}
		case "cove_invite":
			NotificationCenter.default.post(name: .navigateToInbox, object: nil, userInfo: [:])
		case "friend_request":
			NotificationCenter.default.post(name: .navigateToFriends, object: nil, userInfo: [:])
		case "friend_request_accepted":
			NotificationCenter.default.post(name: .navigateToFriends, object: nil, userInfo: [:])
		default:
			break
		}
	}
}

enum RSVPService {
	static func update(eventId: String, status: String) async {
		guard let url = URL(string: "\(AppConstants.API.baseURL)/update-event-rsvp") else { return }
		var req = URLRequest(url: url)
		req.httpMethod = "POST"
		req.setValue("application/json", forHTTPHeaderField: "Content-Type")
		if let token = try? await FirebaseAuth.Auth.auth().currentUser?.getIDToken() {
			req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
		}
		let body: [String: Any] = ["eventId": eventId, "status": status]
		req.httpBody = try? JSONSerialization.data(withJSONObject: body)
		_ = try? await URLSession.shared.data(for: req)
	}
} 