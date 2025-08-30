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
		// Use delete endpoint for NOT_GOING status
		let endpoint = status == "NOT_GOING" ? "/remove-event-rsvp" : "/update-event-rsvp"
		guard let url = URL(string: "\(AppConstants.API.baseURL)\(endpoint)") else { return }
		var req = URLRequest(url: url)
		req.httpMethod = "POST"
		req.setValue("application/json", forHTTPHeaderField: "Content-Type")
		if let token = try? await FirebaseAuth.Auth.auth().currentUser?.getIDToken() {
			req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
		}
		let body: [String: Any] = status == "NOT_GOING" ? ["eventId": eventId] : ["eventId": eventId, "status": status]
		req.httpBody = try? JSONSerialization.data(withJSONObject: body)
		
		// Make the request and handle response
		do {
			let (data, response) = try await URLSession.shared.data(for: req)
			
			// Check if the response is successful
			if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
				// Try to decode the response to check for any errors
				if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
				   let message = json["message"] as? String {
					print("RSVP operation successful: \(message)")
				}
			} else {
				print("RSVP operation failed with status: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
			}
		} catch {
			print("RSVP operation error: \(error)")
		}
	}
} 