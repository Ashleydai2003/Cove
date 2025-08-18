import Foundation
import FirebaseAuth

enum TokenUploader {
	static func upload(token: String) {
		guard let user = Auth.auth().currentUser else { return }
		user.getIDToken { idToken, err in
			guard let idToken = idToken, err == nil else { return }
			guard let url = URL(string: "\(AppConstants.API.baseURL)/update-fcm-token") else { return }
			var req = URLRequest(url: url)
			req.httpMethod = "POST"
			req.setValue("application/json", forHTTPHeaderField: "Content-Type")
			req.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
			let body: [String: Any] = [
				"fcmToken": token,
				"platform": "ios",
				"app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0",
				"locale": Locale.current.identifier
			]
			req.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
			URLSession.shared.dataTask(with: req).resume()
		}
	}
} 