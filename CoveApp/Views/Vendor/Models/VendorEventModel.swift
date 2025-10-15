//
//  VendorEventModel.swift
//  Cove
//
//  Vendor-specific event model that extends NewEventModel but uses vendor network calls
//

import SwiftUI
import UIKit
import Foundation
import FirebaseAuth

/// Model for creating new events in vendor context, following MVVM pattern
@MainActor
class VendorEventModel: ObservableObject {
    // MARK: - Published Properties (identical to NewEventModel)
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
    @Published var isPublic: Bool = true  // Vendor events are always discoverable
    
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

    // MARK: - Computed Properties (identical to NewEventModel)
    var isFormValid: Bool {
        // Only event name and location are required
        return !eventName.isEmpty && location != nil
    }

    // MARK: - Methods (identical to NewEventModel)

    /// Validates and formats ticket price input to ensure only valid decimal numbers
    func validateTicketPriceInput(_ input: String) -> String {
        // Remove any non-numeric characters except decimal point
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

    /// Resets the form to initial state
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
        isPublic = true  // Vendor events are always discoverable
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

    /// Submits the event to the backend using vendor network calls
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
        // For tiered pricing, auto-calculate total spots from all tiers
        if useTieredPricing {
            var totalSpots = 0
            if let earlyBird = Int(earlyBirdSpots) {
                totalSpots += earlyBird
            }
            if let regular = Int(regularSpots) {
                totalSpots += regular
            }
            if let lastMinute = Int(lastMinuteSpots) {
                totalSpots += lastMinute
            }
            // Only set memberCap if there are spots in any tier
            if totalSpots > 0 {
                memberCap = totalSpots
            }
        } else {
            // For single pricing, use the numberOfSpots field
            if !numberOfSpots.isEmpty, let spots = Int(numberOfSpots) {
                memberCap = spots
            }
        }
        
        if !ticketPriceString.isEmpty, let price = Double(ticketPriceString) {
            ticketPrice = price
        }

        // Convert the combined date string back to a Date object for vendor API
        let formatter = ISO8601DateFormatter()
        let combinedDate = formatter.date(from: finalDate) ?? self.eventDate

        // Use vendor network manager instead of regular network manager
        VendorNetworkManager.shared.createVendorEvent(
            name: eventName,
            description: descriptionText.isEmpty ? nil : descriptionText,
            date: combinedDate,
            location: location,
            memberCap: memberCap,
            ticketPrice: ticketPrice,
            paymentHandle: paymentHandle.isEmpty ? nil : paymentHandle,
            coverPhoto: eventImage != nil ? eventImage?.jpegData(compressionQuality: 0.8)?.base64EncodedString() : nil,
            useTieredPricing: useTieredPricing,
            pricingTiers: useTieredPricing ? buildPricingTiers() : nil
        ) { (result: Result<VendorCreateEventResponse, NetworkError>) in
            DispatchQueue.main.async {
                self.isSubmitting = false

                switch result {
                case .success(let response):
                    print("✅ Vendor event created successfully: \(response)")
                    self.resetForm()
                    completion(true)
                case .failure(let error):
                    print("❌ Vendor event creation failed: \(error)")
                    self.errorMessage = "Failed to create event: \(error.localizedDescription)"
                    completion(false)
                }
            }
        }
    }

    /// Builds pricing tiers array for tiered pricing
    private func buildPricingTiers() -> [[String: Any]] {
        var pricingTiers: [[String: Any]] = []
        
        // Early Bird Tier
        if !earlyBirdPrice.isEmpty, let price = Double(earlyBirdPrice) {
            var tier: [String: Any] = [
                "tierType": "Early Bird",
                "price": price,
                "sortOrder": 1
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
                "price": price,
                "sortOrder": 2
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
                "price": price,
                "sortOrder": 3
            ]
            if !lastMinuteSpots.isEmpty, let spots = Int(lastMinuteSpots) {
                tier["maxSpots"] = spots
            }
            pricingTiers.append(tier)
        }
        
        return pricingTiers
    }

    /// Combines date and time into an ISO 8601 string
    private func combineDateTime(date: Date, time: Date, calendar: Calendar = Calendar.current) -> String? {
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        
        var combinedComponents = DateComponents()
        combinedComponents.year = dateComponents.year
        combinedComponents.month = dateComponents.month
        combinedComponents.day = dateComponents.day
        combinedComponents.hour = timeComponents.hour
        combinedComponents.minute = timeComponents.minute
        
        guard let combinedDate = calendar.date(from: combinedComponents) else {
            return nil
        }
        
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: combinedDate)
    }
}

// MARK: - Vendor Event Response Models

/// API response for vendor event creation
struct VendorCreateEventResponse: Decodable {
    let message: String
    let event: VendorCreatedEvent
}

/// VendorCreatedEvent: Used for vendor event creation responses
struct VendorCreatedEvent: Decodable {
    let id: String
    let name: String
    let date: String
    let location: String
    let isPublic: Bool
    let vendorId: String
    let coverPhotoID: String?
}
