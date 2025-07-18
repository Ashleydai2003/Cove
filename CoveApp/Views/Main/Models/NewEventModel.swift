//
//  NewEventModel.swift
//  Cove
//
//  Created by Assistant

import SwiftUI
import Foundation
import FirebaseAuth

/// Model for creating new events, following MVVM pattern
@MainActor
class NewEventModel: ObservableObject {
    // MARK: - Published Properties
    @Published var eventName: String = ""
    @Published var eventDate = Date()
    @Published var eventTime = Date()
    @Published var numberOfSpots: String = ""
    @Published var eventImage: UIImage?
    @Published var location: String?
    @Published var coveId: String = ""
    @Published var isSubmitting = false
    @Published var errorMessage: String?

    // Sheet States
    @Published var showImagePicker: Bool = false
    @Published var showLocationPicker: Bool = false
    @Published var showDatePicker: Bool = false
    @Published var showTimePicker: Bool = false

    // MARK: - Computed Properties
    var isFormValid: Bool {
        // Only event name and location are required
        return !eventName.isEmpty && location != nil
    }

    // MARK: - Methods

    /// Resets all form fields to their initial state
    func resetForm() {
        eventName = ""
        eventDate = Date()
        eventTime = Date()
        numberOfSpots = ""
        eventImage = nil
        location = nil
        coveId = ""
        isSubmitting = false
        errorMessage = nil
        showImagePicker = false
        showLocationPicker = false
        showDatePicker = false
        showTimePicker = false
    }

    /// Submits the event to the backend
    func submitEvent(completion: @escaping (Bool) -> Void) {
        guard isFormValid else {
            errorMessage = "Please fill in all required fields"
            completion(false)
            return
        }

        guard let location = self.location else {
            errorMessage = "Location is required"
            completion(false)
            return
        }

        isSubmitting = true
        errorMessage = nil

        // Format date to ISO 8601
        let finalDate: String = combineDateTime(date: eventDate, time: eventTime) ?? ""

        // Build parameters with optional cover photo
        var params: [String: Any] = [
            "name": eventName,
            "description": "",
            "date": finalDate,
            "location": location,
            "coveId": coveId
        ]

        // Debug: Log the current userId from Firebase Auth
        let firebaseUserId = Auth.auth().currentUser?.uid ?? "no-firebase-user"
        Log.critical("Creating event - Firebase userId: '\(firebaseUserId)', ProfileModel userId: '\(AppController.shared.profileModel.userId)'")

        // Add cover photo if provided
        if let image = eventImage,
           let coverPhoto = image.jpegData(compressionQuality: 0.8) {
            params["coverPhoto"] = coverPhoto.base64EncodedString()
        }

        NetworkManager.shared.post(
            endpoint: "/create-event",
            parameters: params
        ) { (result: Result<CreateEventResponse, NetworkError>) in
            DispatchQueue.main.async {
                self.isSubmitting = false

                switch result {
                case .success(let response):
                    Log.debug("✅ Event created successfully: \(response)")
                    self.resetForm()
                    completion(true)
                case .failure(let error):
                    Log.error("Event creation failed: \(error)")
                    self.errorMessage = "Failed to create event: \(error.localizedDescription)"
                    completion(false)
                }
            }
        }
    }

    /// Combines date and time into an ISO 8601 string
    private func combineDateTime(date: Date, time: Date, calendar: Calendar = Calendar.current) -> String? {
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: time)

        var combinedComponents = DateComponents()
        combinedComponents.year = dateComponents.year
        combinedComponents.month = dateComponents.month
        combinedComponents.day = dateComponents.day
        combinedComponents.hour = timeComponents.hour
        combinedComponents.minute = timeComponents.minute
        combinedComponents.second = timeComponents.second

        guard let combinedDate = calendar.date(from: combinedComponents) else { return nil }

        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        return formatter.string(from: combinedDate)
    }
}

// MARK: - Response Models

/// API response for event creation
struct CreateEventResponse: Decodable {
    let message: String
    let event: CreatedEvent
}

/// CreatedEvent: Used for event creation responses
struct CreatedEvent: Decodable {
    let id: String
    let name: String
    let description: String?
    let date: String
    let location: String
    let coveId: String
    let createdAt: String
}

