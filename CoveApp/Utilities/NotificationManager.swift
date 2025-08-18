import Foundation
import UIKit
import UserNotifications

enum NotificationCategoryIDs {
	static let event = "EVENT_CATEGORY"
}

enum NotificationActionIDs {
	static let rsvpYes = "RSVP_YES"
	static let rsvpNo  = "RSVP_NO"
}

enum NotificationManager {
	static func requestAuthorization() {
		let center = UNUserNotificationCenter.current()
		center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
			if let error = error { Log.error("Notif auth error: \(error)") }
			if !granted { Log.debug("Notifications not granted") }
		}
		registerCategories()
	}
	
	static func registerCategories() {
		let yes = UNNotificationAction(
			identifier: NotificationActionIDs.rsvpYes,
			title: "Yes",
			options: [.authenticationRequired]
		)
		let no = UNNotificationAction(
			identifier: NotificationActionIDs.rsvpNo,
			title: "No",
			options: [.destructive]
		)
		let event = UNNotificationCategory(
			identifier: NotificationCategoryIDs.event,
			actions: [yes, no],
			intentIdentifiers: [],
			options: [.customDismissAction]
		)
		UNUserNotificationCenter.current().setNotificationCategories([event])
	}
	
	static func openSystemSettings() {
		guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
		UIApplication.shared.open(url)
	}
} 