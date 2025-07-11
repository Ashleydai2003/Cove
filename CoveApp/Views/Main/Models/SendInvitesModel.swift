import Foundation
import Combine

@MainActor
class SendInvitesModel: ObservableObject {
    let coveId: String
    @Published var phoneNumbers: [String] = [""]
    @Published var countryCode: String = "+1"
    @Published var message: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var inviteResults: [InviteResult] = []
    @Published var showResults = false
    
    /// Computed property to check if form is valid for submission
    var isFormValid: Bool {
        return !getValidPhoneNumbers().isEmpty
    }
    
    init(coveId: String, initialPhoneNumbers: [String] = [], initialMessage: String = "") {
        self.coveId = coveId
        
        // Set initial values or defaults
        if initialPhoneNumbers.isEmpty {
            self.phoneNumbers = [""]
        } else {
            // Convert formatted phone numbers back to display format
            self.phoneNumbers = initialPhoneNumbers.map { formattedNumber in
                // Remove the country code for display if it matches the current country code
                if formattedNumber.starts(with: "+1") && formattedNumber.count > 2 {
                    return String(formattedNumber.dropFirst(2)) // Remove "+1"
                } else if formattedNumber.starts(with: "+") {
                    // For other country codes, just remove the +
                    return String(formattedNumber.dropFirst())
                } else {
                    return formattedNumber
                }
            }
        }
        
        self.message = initialMessage
    }
    
    struct InviteResult {
        let phoneNumber: String
        let success: Bool
        let error: String?
    }
    
    struct SendInviteResponse: Codable {
        let message: String
        let invites: [SentInvite]
        let errors: [InviteError]?
        
        struct SentInvite: Codable {
            let id: String
            let phoneNumber: String
            let createdAt: String
        }
        
        struct InviteError: Codable {
            let phoneNumber: String
            let error: String
        }
    }
    
    /// Adds a new empty phone number field
    func addPhoneNumber() {
        phoneNumbers.append("")
    }
    
    /// Removes a phone number at the specified index
    func removePhoneNumber(at index: Int) {
        guard phoneNumbers.count > 1 && index >= 0 && index < phoneNumbers.count else { return }
        phoneNumbers.remove(at: index)
    }
    
    /// Updates phone number at specific index
    func updatePhoneNumber(at index: Int, with value: String) {
        guard index >= 0 && index < phoneNumbers.count else { return }
        phoneNumbers[index] = value
    }
    
    /// Validates phone numbers and returns clean list with proper formatting
    func getValidPhoneNumbers() -> [String] {
        return phoneNumbers
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map { phoneNumber in
                // Format phone number with the selected country code
                let cleanCountryCode = countryCode.trimmingCharacters(in: .whitespacesAndNewlines)
                
                // If phone number already starts with +, use as-is
                if phoneNumber.starts(with: "+") {
                    return phoneNumber
                }
                
                // If phone number starts with the country code digits (without +), add +
                let countryCodeDigits = String(cleanCountryCode.dropFirst()) // Remove the + from country code
                if phoneNumber.starts(with: countryCodeDigits) {
                    return "+" + phoneNumber
                }
                
                // Otherwise, prepend the full country code
                return cleanCountryCode + phoneNumber
            }
    }
    
    /// Sends invites to the specified cove
    func sendInvites() {
        let validPhoneNumbers = getValidPhoneNumbers()
        
        guard !validPhoneNumbers.isEmpty else {
            errorMessage = "Please enter at least one phone number"
            return
        }
        
        isLoading = true
        errorMessage = nil
        successMessage = nil
        inviteResults = []
        
        // Prepare request body
        var requestBody: [String: Any] = [
            "coveId": self.coveId,
            "phoneNumbers": validPhoneNumbers
        ]
        
        // Add message only if it's not empty
        if !message.isEmpty {
            requestBody["message"] = message
        }
        
        print("📤 Sending invites request")
        print("📤 Request body: \(requestBody)")
        
        // Use NetworkManager to make the request
        NetworkManager.shared.post(
            endpoint: "/send-invite",
            parameters: requestBody
        ) { [weak self] (result: Result<SendInviteResponse, NetworkError>) in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let sendInviteResponse):
                    // Process results
                    var results: [InviteResult] = []
                    
                    // Add successful invites
                    for invite in sendInviteResponse.invites {
                        results.append(InviteResult(
                            phoneNumber: invite.phoneNumber,
                            success: true,
                            error: nil
                        ))
                    }
                    
                    // Add failed invites
                    if let errors = sendInviteResponse.errors {
                        for error in errors {
                            results.append(InviteResult(
                                phoneNumber: error.phoneNumber,
                                success: false,
                                error: error.error
                            ))
                        }
                    }
                    
                    self.inviteResults = results
                    
                    let successCount = sendInviteResponse.invites.count
                    let totalCount = validPhoneNumbers.count
                    let _ = sendInviteResponse.errors?.count ?? 0
                    let duplicateCount = sendInviteResponse.errors?.filter { $0.error.contains("already exists") }.count ?? 0
                    let memberCount = sendInviteResponse.errors?.filter { $0.error.contains("already a member") }.count ?? 0
                    
                    // Create detailed success message
                    if successCount == totalCount {
                        self.successMessage = "Successfully sent \(successCount) invite\(successCount == 1 ? "" : "s")!"
                    } else if successCount > 0 {
                        var messageParts: [String] = ["Sent \(successCount) of \(totalCount) invites"]
                        
                        if duplicateCount > 0 {
                            messageParts.append("\(duplicateCount) already invited")
                        }
                        if memberCount > 0 {
                            messageParts.append("\(memberCount) already members")
                        }
                        
                        self.successMessage = messageParts.joined(separator: ", ")
                    } else {
                        // No invites sent
                        if duplicateCount == totalCount {
                            self.errorMessage = "All selected numbers have already been invited to this cove"
                        } else if memberCount == totalCount {
                            self.errorMessage = "All selected numbers are already members of this cove"
                        } else if duplicateCount > 0 || memberCount > 0 {
                            self.errorMessage = "No new invites sent - see details below"
                        } else {
                            self.errorMessage = "No invites were sent"
                        }
                    }
                    
                    self.showResults = true
                    
                case .failure(let error):
                    print("❌ Send invites error: \(error)")
                    self.errorMessage = "Failed to send invites: \(error.localizedDescription)"
                }
            }
        }
    }
    
    /// Resets the form for sending new invites
    func resetForm() {
        phoneNumbers = [""]
        message = ""
        errorMessage = nil
        successMessage = nil
        inviteResults = []
        showResults = false
        isLoading = false
    }
    
    /// Converts a formatted phone number back to display format
    private func toDisplayFormat(_ formattedNumber: String) -> String {
        // Remove the current country code for display
        let currentCountryCode = countryCode
        if formattedNumber.starts(with: currentCountryCode) && formattedNumber.count > currentCountryCode.count {
            return String(formattedNumber.dropFirst(currentCountryCode.count))
        }
        return formattedNumber
    }
} 