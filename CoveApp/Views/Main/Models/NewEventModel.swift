//
//  NewEventModel.swift
//  Cove
//
//  Created by Assistant

import SwiftUI
import UIKit
import Foundation
import FirebaseAuth

/// Model for creating new events, following MVVM pattern
@MainActor
class NewEventModel: ObservableObject {
    // MARK: - Published Properties
    @Published var eventName: String = ""
    @Published var descriptionText: String = ""
    @Published var eventDate = Date()
    @Published var eventTime = Date()
    @Published var numberOfSpots: String = ""
    @Published var ticketPriceString: String = ""
    @Published var paymentHandle: String = ""
    @Published var memberCap: Int?
    @Published var ticketPrice: Double?
    @Published var eventImage: UIImage?
    @Published var location: String?
    @Published var coveId: String = ""
    @Published var isSubmitting = false
    @Published var errorMessage: String?
    @Published var isPublic: Bool = false
    
    // Advanced Options
    @Published var showAdvancedOptions: Bool = false
    @Published var useTieredPricing: Bool = false
    
    // Tiered Pricing
    @Published var earlyBirdPrice: String = ""
    @Published var earlyBirdSpots: String = ""
    @Published var regularPrice: String = ""
    @Published var regularSpots: String = ""
    @Published var lastMinutePrice: String = ""
    @Published var lastMinuteSpots: String = ""

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

    /// Validates and formats ticket price input to ensure only valid decimal numbers
    func validateTicketPriceInput(_ input: String) -> String {
        // Remove any non-numeric characters except decimal point
        let filtered = input.filter { $0.isNumber || $0 == "." }
        
        // Ensure only one decimal point
        let components = filtered.components(separatedBy: ".")
        if components.count > 2 {
            // If more than one decimal point, keep only the first one
            return components[0] + "." + components[1...].joined()
        }
        
        // Limit to 2 decimal places
        if components.count == 2 && components[1].count > 2 {
            return components[0] + "." + String(components[1].prefix(2))
        }
        
        return filtered
    }

    /// Validates number of spots input to ensure only integers
    func validateNumberOfSpotsInput(_ input: String) -> String {
        // Remove any non-numeric characters
        return input.filter { $0.isNumber }
    }
    
    /// Validates tiered pricing price input
    func validateTieredPriceInput(_ input: String) -> String {
        let filtered = input.filter { $0.isNumber || $0 == "." }
        
        // Ensure only one decimal point
        let components = filtered.components(separatedBy: ".")
        if components.count > 2 {
            return components[0] + "." + components[1...].joined()
        }
        
        // Limit to 2 decimal places
        if components.count == 2 && components[1].count > 2 {
            return components[0] + "." + String(components[1].prefix(2))
        }
        
        return filtered
    }
    
    /// Validates tiered pricing spots input
    func validateTieredSpotsInput(_ input: String) -> String {
        return input.filter { $0.isNumber }
    }

    /// Resets all form fields to their initial state
    func resetForm() {
        eventName = ""
        descriptionText = ""
        eventDate = Date()
        eventTime = Date()
        numberOfSpots = ""
        ticketPriceString = ""
        paymentHandle = ""
        memberCap = nil
        ticketPrice = nil
        eventImage = nil
        location = nil
        coveId = ""
        isSubmitting = false
        errorMessage = nil
        isPublic = false
        showAdvancedOptions = false
        useTieredPricing = false
        earlyBirdPrice = ""
        earlyBirdSpots = ""
        regularPrice = ""
        regularSpots = ""
        lastMinutePrice = ""
        lastMinuteSpots = ""
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

        // Convert string inputs to appropriate types
        if !numberOfSpots.isEmpty, let spots = Int(numberOfSpots) {
            memberCap = spots
        }
        
        if !ticketPriceString.isEmpty, let price = Double(ticketPriceString) {
            ticketPrice = price
        }

        // Build parameters with optional fields
        var params: [String: Any] = [
            "name": eventName,
            "date": finalDate,
            "location": location,
            "coveId": coveId,
            "isPublic": isPublic,
            "useTieredPricing": useTieredPricing
        ]

        // Add optional fields if they have values
        if !descriptionText.isEmpty {
            params["description"] = descriptionText
        }
        
        if let memberCap = memberCap {
            params["memberCap"] = memberCap
        }
        
        if !paymentHandle.isEmpty {
            params["paymentHandle"] = paymentHandle
        }
        
        // Handle pricing based on tiered pricing setting
        if useTieredPricing {
            // Build pricing tiers array
            var pricingTiers: [[String: Any]] = []
            
            // Early Bird Tier
            if !earlyBirdPrice.isEmpty, let price = Double(earlyBirdPrice) {
                var tier: [String: Any] = [
                    "tierType": "Early Bird",
                    "price": price
                ]
                if !earlyBirdSpots.isEmpty, let spots = Int(earlyBirdSpots) {
                    tier["maxSpots"] = spots
                }
                pricingTiers.append(tier)
            }
            
            // Regular Tier
            if !regularPrice.isEmpty, let price = Double(regularPrice) {
                var tier: [String: Any] = [
                    "tierType": "Regular",
                    "price": price
                ]
                if !regularSpots.isEmpty, let spots = Int(regularSpots) {
                    tier["maxSpots"] = spots
                }
                pricingTiers.append(tier)
            }
            
            // Last Minute Tier
            if !lastMinutePrice.isEmpty, let price = Double(lastMinutePrice) {
                var tier: [String: Any] = [
                    "tierType": "Last Minute",
                    "price": price
                ]
                if !lastMinuteSpots.isEmpty, let spots = Int(lastMinuteSpots) {
                    tier["maxSpots"] = spots
                }
                pricingTiers.append(tier)
            }
            
            if !pricingTiers.isEmpty {
                params["pricingTiers"] = pricingTiers
            }
        } else {
            // Use single ticket price if not using tiered pricing
            if let ticketPrice = ticketPrice {
                params["ticketPrice"] = ticketPrice
            }
        }

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
    let memberCap: Int?
    let ticketPrice: Double?
    let coveId: String
    let createdAt: String
}

