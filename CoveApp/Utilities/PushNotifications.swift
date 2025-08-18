import Foundation
import FirebaseAuth
import FirebaseMessaging

struct PushNotifications {
	static func clearTokenOnLogout() {
		Task {
			// Best-effort: delete local FCM token so a new one is issued for the next session
			do {
				try await Messaging.messaging().deleteToken()
				Log.debug("Cleared local FCM token")
			} catch {
				Log.error("Failed to delete FCM token: \(error)")
			}
			// Inform backend to clear stored token
			await postToken(nil)
		}
	}
	
	@discardableResult
	private static func postToken(_ token: String?) async -> Bool {
		guard let url = URL(string: "\(AppConstants.API.baseURL)/update-fcm-token") else { return false }
		var request = URLRequest(url: url)
		request.httpMethod = "POST"
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		
		if let user = Auth.auth().currentUser {
			do {
				let idToken = try await user.getIDToken()
				request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
			} catch {
				Log.error("Failed to get ID token for posting FCM token: \(error)")
			}
		}
		
		let body: [String: Any?] = ["fcmToken": token]
		request.httpBody = try? JSONSerialization.data(withJSONObject: body.compactMapValues { $0 })
		
		do {
			let (_, response) = try await URLSession.shared.data(for: request)
			if let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) {
				return true
			}
			Log.error("Failed posting FCM token, status: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
			return false
		} catch {
			Log.error("Network error posting FCM token: \(error)")
			return false
		}
	}
} 