import Foundation
import Combine

@MainActor
class SendInvitesModel: ObservableObject {
    let coveId: String
    @Published var phoneNumbers: [String] = [""]
    @Published var countries: [Country] = []
    @Published var phoneNumberIds: [UUID] = [] // Add UUIDs for stable identification
    @Published var message: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var inviteResults: [InviteResult] = []
    @Published var showResults = false

    /// Available countries loaded from JSON
    let availableCountries: [Country] = Bundle.main.decode("CountryList.json")

    /// Computed property to check if form is valid for submission
    var isFormValid: Bool {
        return !getValidPhoneNumbers().isEmpty
    }

    init(coveId: String, initialPhoneNumbers: [String] = [], initialMessage: String = "") {
        self.coveId = coveId

        // Set initial values or defaults
        if initialPhoneNumbers.isEmpty {
            self.phoneNumbers = [""]
            self.countries = [Country(id: "0235", name: "USA", flag: "🇺🇸", code: "US", dial_code: "+1", pattern: "### ### ####", limit: 17)]
            self.phoneNumberIds = [UUID()]
        } else {
            // Convert formatted phone numbers back to display format
            self.phoneNumbers = initialPhoneNumbers.map { formattedNumber in
                // Remove the country code for display if it matches the default country code
                let defaultCountry = Country(id: "0235", name: "USA", flag: "🇺🇸", code: "US", dial_code: "+1", pattern: "### ### ####", limit: 17)
                if formattedNumber.starts(with: defaultCountry.dial_code) && formattedNumber.count > defaultCountry.dial_code.count {
                    return String(formattedNumber.dropFirst(defaultCountry.dial_code.count))
                } else if formattedNumber.starts(with: "+") {
                    // For other country codes, just remove the +
                    return String(formattedNumber.dropFirst())
                } else {
                    return formattedNumber
                }
            }
            self.countries = Array(repeating: Country(id: "0235", name: "USA", flag: "🇺🇸", code: "US", dial_code: "+1", pattern: "### ### ####", limit: 17), count: initialPhoneNumbers.count)
            self.phoneNumberIds = Array(repeating: UUID(), count: initialPhoneNumbers.count)
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

    /// Adds a new empty phone number field with default country
    func addPhoneNumber() {
        phoneNumbers.append("")
        countries.append(Country(id: "0235", name: "USA", flag: "🇺🇸", code: "US", dial_code: "+1", pattern: "### ### ####", limit: 17))
        phoneNumberIds.append(UUID())
    }

    /// Removes a phone number at the specified index
    func removePhoneNumber(at index: Int) {
        guard phoneNumbers.count > 1 && index >= 0 && index < phoneNumbers.count else { return }
        phoneNumbers.remove(at: index)
        countries.remove(at: index)
        phoneNumberIds.remove(at: index)
    }

    /// Updates phone number at specific index (value is already formatted from view)
    func updatePhoneNumber(at index: Int, with value: String) {
        guard index >= 0 && index < phoneNumbers.count && index < countries.count else { return }

        // Value is already formatted from the view, just set it
        phoneNumbers[index] = value
    }

    /// Updates country at specific index
    func updateCountry(at index: Int, with country: Country) {
        guard index >= 0 && index < countries.count else { return }
        countries[index] = country

        // Reformat the phone number for the new country
        if index < phoneNumbers.count {
            let currentNumber = phoneNumbers[index]
            let formattedNumber = formatPhoneNumber(currentNumber, pattern: country.pattern)
            phoneNumbers[index] = formattedNumber
        }
    }

    /// Formats a phone number according to the provided pattern (exactly like UserPhoneNumber)
    /// - Parameters:
    ///   - number: Raw phone number string
    ///   - pattern: Format pattern (e.g., "### ### ####")
    /// - Returns: Formatted phone number string
    func formatPhoneNumber(_ number: String, pattern: String) -> String {
        // Input validation
        guard !number.isEmpty else { return "" }

        // Remove all non-digit characters
        let cleanNumber = number.filter { $0.isNumber }

        // Get the maximum number of digits allowed by the pattern
        let maxDigits = pattern.filter { $0 == "#" }.count

        // Truncate the number if it exceeds the pattern's limit
        let truncatedNumber = String(cleanNumber.prefix(maxDigits))

        var result = ""
        var numberIndex = truncatedNumber.startIndex

        // Iterate through the pattern
        for patternChar in pattern {
            if patternChar == "#" {
                if numberIndex < truncatedNumber.endIndex {
                    result.append(truncatedNumber[numberIndex])
                    numberIndex = truncatedNumber.index(after: numberIndex)
                }
            } else {
                // Only add the separator if we have more digits to come
                if numberIndex < truncatedNumber.endIndex {
                    result.append(patternChar)
                }
            }
        }

        return result
    }

    /// Validates if a phone number matches the required pattern and doesn't exceed the country's limit (exactly like UserPhoneNumber)
    /// - Parameters:
    ///   - number: Phone number to validate
    ///   - pattern: Required format pattern
    ///   - country: Country for validation
    /// - Returns: Boolean indicating if the number is valid
    func isValidPhoneNumber(_ number: String, pattern: String, country: Country) -> Bool {
        // Input validation
        guard !number.isEmpty else { return false }

        // Get clean number (digits only)
        let cleanNumber = number.filter { $0.isNumber }
        let requiredDigits = pattern.filter { $0 == "#" }.count

        // Check if the number matches the pattern's digit count
        guard cleanNumber.count == requiredDigits else { return false }

        // Check if the total length (country code + number) doesn't exceed the limit
        let countryCodeDigits = country.dial_code.filter { $0.isNumber }
        let totalLength = countryCodeDigits.count + cleanNumber.count

        guard totalLength <= country.limit else {
            return false
        }
        return true
    }

    /// Returns the full phone number in E.164 format (exactly like UserPhoneNumber)
    func getFullPhoneNumber(for number: String, country: Country) -> String {
        // Remove all non-digit characters from the local number
        let cleanLocalNumber = number.filter { $0.isNumber }

        // Combine country code and local number
        return country.dial_code + cleanLocalNumber
    }

    /// Checks if the phone number matches the expected length for the selected country (exactly like UserPhoneNumber)
    private func checkPhoneNumberCompletion(_ number: String, country: Country) -> Bool {
        let digitsOnly = number.filter { $0.isNumber }
        let expectedLength = country.pattern.filter { $0 == "#" }.count
        return digitsOnly.count == expectedLength
    }

    /// Validates phone numbers and returns clean list with proper formatting
    func getValidPhoneNumbers() -> [String] {
        var validNumbers: [String] = []

        for (index, phoneNumber) in phoneNumbers.enumerated() {
            let trimmedNumber = phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)

            guard !trimmedNumber.isEmpty && index < countries.count else { continue }

            let country = countries[index]

            // Validate the phone number first
            guard isValidPhoneNumber(trimmedNumber, pattern: country.pattern, country: country) else {
                continue
            }

            // Return the full phone number in E.164 format
            validNumbers.append(getFullPhoneNumber(for: trimmedNumber, country: country))
        }

        return validNumbers
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

        Log.debug("📤 Sending invites request")
        Log.debug("📤 Request body: \(requestBody)")

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

                    // Show success message
                    let successCount = sendInviteResponse.invites.count
                    let totalCount = validPhoneNumbers.count

                    if successCount == totalCount {
                        self.successMessage = "All invites sent successfully!"
                    } else {
                        self.successMessage = "\(successCount) out of \(totalCount) invites sent successfully"
                    }

                    self.showResults = true

                case .failure(let error):
                    Log.error("Failed to send invites: \(error.localizedDescription)")
                    self.errorMessage = "Failed to send invites: \(error.localizedDescription)"
                }
            }
        }
    }

    /// Resets the form for sending new invites
    func resetForm() {
        phoneNumbers = [""]
        countries = [Country(id: "0235", name: "USA", flag: "🇺🇸", code: "US", dial_code: "+1", pattern: "### ### ####", limit: 17)]
        phoneNumberIds = [UUID()]
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
        let currentCountryCode = countries[0].dial_code // Assuming the first country is the default for display
        if formattedNumber.starts(with: currentCountryCode) && formattedNumber.count > currentCountryCode.count {
            return String(formattedNumber.dropFirst(currentCountryCode.count))
        }
        return formattedNumber
    }
}
