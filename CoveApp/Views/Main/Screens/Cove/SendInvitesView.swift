import SwiftUI

struct SendInvitesView: View {
    let coveId: String
    let coveName: String
    let sendAction: (() -> Void)?
    let onDataSubmit: (([String], String) -> Void)?
    
    @StateObject private var viewModel: SendInvitesModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Int?
    @State private var presentCountrySheet = false
    @State private var searchCountry: String = ""
    @State private var selectedFieldIndex: Int = 0 // Track which field's country is being selected
    
    init(coveId: String, coveName: String, sendAction: (() -> Void)? = nil, onDataSubmit: (([String], String) -> Void)? = nil, initialPhoneNumbers: [String] = [], initialMessage: String = "") {
        self.coveId = coveId
        self.coveName = coveName
        self.sendAction = sendAction
        self.onDataSubmit = onDataSubmit
        self._viewModel = StateObject(wrappedValue: SendInvitesModel(coveId: coveId, initialPhoneNumbers: initialPhoneNumbers, initialMessage: initialMessage))
    }
    
    // Custom input accessory view for keyboard (exactly like UserPhoneNumberView)
    private var keyboardAccessoryView: some View {
        HStack {
            Spacer()
            Button("Done") {
                focusedField = nil
            }
            .padding(.trailing, 16)
            .padding(.vertical, 8)
        }
        .background(Color(.systemGray6))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Colors.faf8f4.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            // Header with cove name
                            VStack(alignment: .leading, spacing: 8) {
                                Text("invite friends to")
                                    .font(.LibreBodoni(size: 16))
                                    .foregroundColor(Colors.k292929)
                                
                                Text(coveName)
                                    .font(.LibreBodoniBold(size: 24))
                                    .foregroundColor(Colors.primaryDark)
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 50)
                            
                            // Phone numbers section
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Text("phone numbers")
                                        .font(.LibreBodoniBold(size: 18))
                                        .foregroundColor(Colors.primaryDark)
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        viewModel.addPhoneNumber()
                                        // Focus on the new field
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                            focusedField = viewModel.phoneNumbers.count - 1
                                        }
                                    }) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(Colors.primaryDark)
                                    }
                                }
                                .padding(.horizontal, 24)
                                
                                // Phone number inputs (exactly like UserPhoneNumberView structure)
                                ForEach(Array(viewModel.phoneNumbers.enumerated()), id: \.offset) { index, phoneNumber in
                                    PhoneNumberInputView(
                                        phoneNumber: Binding(
                                            get: { viewModel.phoneNumbers[index] },
                                            set: { viewModel.phoneNumbers[index] = $0 }
                                        ),
                                        selectedCountry: index < viewModel.countries.count ? viewModel.countries[index] : Country(id: "0235", name: "USA", flag: "🇺🇸", code: "US", dial_code: "+1", pattern: "### ### ####", limit: 17),
                                        index: index,
                                        canRemove: viewModel.phoneNumbers.count > 1,
                                        onCountryTapped: {
                                            selectedFieldIndex = index
                                            presentCountrySheet = true
                                        },
                                        onRemove: {
                                            viewModel.removePhoneNumber(at: index)
                                        },
                                        keyboardAccessoryView: keyboardAccessoryView
                                    )
                                    .focused($focusedField, equals: index)
                                }
                            }
                            
                            // Message section
                            VStack(alignment: .leading, spacing: 12) {
                                Text("invitation message (optional)")
                                    .font(.LibreBodoniBold(size: 18))
                                    .foregroundColor(Colors.primaryDark)
                                    .padding(.horizontal, 24)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    TextEditor(text: $viewModel.message)
                                        .font(.LibreBodoni(size: 16))
                                        .foregroundColor(Colors.k292929)
                                        .padding(16)
                                        .frame(minHeight: 100)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.white)
                                                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                        )
                                    
                                    Text("add a personal touch to your invitation")
                                        .font(.LibreBodoni(size: 12))
                                        .foregroundColor(.gray)
                                }
                                .padding(.horizontal, 24)
                            }
                            
                            // Results section
                            if viewModel.showResults {
                                ResultsView(results: viewModel.inviteResults)
                                    .padding(.horizontal, 24)
                            }
                            
                            // Error/Success messages
                            if let errorMessage = viewModel.errorMessage {
                                Text(errorMessage)
                                    .font(.LibreBodoni(size: 14))
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 24)
                            }
                            
                            if let successMessage = viewModel.successMessage {
                                Text(successMessage)
                                    .font(.LibreBodoni(size: 14))
                                    .foregroundColor(.green)
                                    .padding(.horizontal, 24)
                            }
                            
                            Spacer(minLength: 100) // Space for bottom button
                        }
                    }
                    
                    // Send button at bottom
                    SendInviteButton(
                        isLoading: viewModel.isLoading,
                        isFormValid: viewModel.isFormValid,
                        action: {
                            // First, pass data back if callback is provided
                            if let onDataSubmit = onDataSubmit {
                                let phoneNumbers = viewModel.getValidPhoneNumbers()
                                onDataSubmit(phoneNumbers, viewModel.message)
                            }
                            
                            // Then execute the action
                            if let customAction = sendAction {
                                customAction()
                            } else {
                                viewModel.sendInvites()
                            }
                        }
                    )
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(Colors.primaryDark)
                    }
                }
            }
        }
        // Country selection sheet (exactly like UserPhoneNumberView)
        .sheet(isPresented: $presentCountrySheet) {
            NavigationView {
                List(filteredCountries) { country in
                    Button {
                        viewModel.updateCountry(at: selectedFieldIndex, with: country)
                        presentCountrySheet = false
                        searchCountry = ""
                    } label: {
                        HStack {
                            Text(country.flag)
                            Text(country.name)
                                .font(.body)
                            Spacer()
                            Text(country.dial_code)
                                .foregroundColor(.secondary)
                        }
                    }
                    .listRowBackground(Color.white.opacity(0.08))
                }
                .listStyle(.plain)
                .searchable(text: $searchCountry, prompt: "Your country")
            }
            .presentationDetents([.medium, .large])
        }
        .onAppear {
            // Focus on first field when view appears
            focusedField = 0
        }
    }
    
    /// Filters countries based on search input (exactly like UserPhoneNumberView)
    var filteredCountries: [Country] {
        if searchCountry.isEmpty {
            return viewModel.availableCountries
        } else {
            return viewModel.availableCountries.filter { $0.name.localizedCaseInsensitiveContains(searchCountry) }
        }
    }
}

/// Extracted send button component styled like create button
struct SendInviteButton: View {
    let isLoading: Bool
    let isFormValid: Bool
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.gray.opacity(0.3))
            
            Button(action: action) {
                if isLoading {
                    ProgressView()
                        .tint(.black)
                        .frame(maxWidth: .infinity, minHeight: 60, maxHeight: 60, alignment: .center)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.white)
                        )
                } else {
                    Text("send")
                        .foregroundStyle(!isFormValid ? Color.gray : Color.black)
                        .font(.LibreBodoniBold(size: 16))
                        .frame(maxWidth: .infinity, minHeight: 60, maxHeight: 60, alignment: .center)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(!isFormValid ? Color.gray.opacity(0.3) : Color.white)
                        )
                }
            }
            .disabled(!isFormValid || isLoading)
            .padding(.horizontal, 32)
            .padding(.vertical, 24)
            .background(Colors.faf8f4)
        }
    }
}

/// Individual phone number input field (exactly like UserPhoneNumberView structure)
struct PhoneNumberInputView: View {
    @Binding var phoneNumber: String
    let selectedCountry: Country
    let index: Int
    let canRemove: Bool
    let onCountryTapped: () -> Void
    let onRemove: () -> Void
    let keyboardAccessoryView: AnyView
    
    private enum Constants {
        static let countryButtonWidth: CGFloat = 66
        static let countryFlagFontSize: CGFloat = 30
        static let phoneInputFontSize: CGFloat = 25
        static let downArrowSize: CGSize = .init(width: 19, height: 14)
    }
    
    init(phoneNumber: Binding<String>, selectedCountry: Country, index: Int, canRemove: Bool, onCountryTapped: @escaping () -> Void, onRemove: @escaping () -> Void, keyboardAccessoryView: some View) {
        self._phoneNumber = phoneNumber
        self.selectedCountry = selectedCountry
        self.index = index
        self.canRemove = canRemove
        self.onCountryTapped = onCountryTapped
        self.onRemove = onRemove
        self.keyboardAccessoryView = AnyView(keyboardAccessoryView)
    }
    
    /// Formats a phone number according to the provided pattern (exactly like UserPhoneNumber)
    /// - Parameters:
    ///   - number: Raw phone number string
    ///   - pattern: Format pattern (e.g., "### ### ####")
    /// - Returns: Formatted phone number string
    private func formatPhoneNumber(_ number: String, pattern: String) -> String {
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
    
    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 16) {
            // Country Selection Button (exactly like UserPhoneNumberView)
            Button {
                onCountryTapped()
            } label: {
                HStack {
                    Text(selectedCountry.flag)
                        .foregroundStyle(Color.black)
                        .font(.LibreBodoni(size: Constants.countryFlagFontSize))
                    
                    Image(systemName: "chevron.down")
                        .resizable()
                        .frame(width: Constants.downArrowSize.width, 
                                height: Constants.downArrowSize.height)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: Constants.countryButtonWidth)
            
            // Country code display (exactly like UserPhoneNumberView)
            Text(selectedCountry.dial_code)
                .foregroundStyle(Color.black)
                .font(.LibreCaslon(size: Constants.phoneInputFontSize))
            
            // Phone number input (exactly like UserPhoneNumberView)
            TextField(selectedCountry.pattern, text: $phoneNumber)
                .font(.LibreCaslon(size: Constants.phoneInputFontSize))
                .foregroundStyle(Color.black)
                .keyboardType(.numberPad)
                .textContentType(.telephoneNumber)
                .toolbar {
                    ToolbarItem(placement: .keyboard) {
                        keyboardAccessoryView
                    }
                }
                .onChange(of: phoneNumber) { _, newValue in
                    // Format the phone number exactly like UserPhoneNumberView
                    let formattedNumber = formatPhoneNumber(newValue, pattern: selectedCountry.pattern)
                    phoneNumber = formattedNumber
                }
            
            // Remove button (if applicable)
            if canRemove {
                Button(action: onRemove) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.red)
                }
            }
        }
        .padding(.horizontal, 24)
    }
}

/// Results display view
struct ResultsView: View {
    let results: [SendInvitesModel.InviteResult]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("results")
                .font(.LibreBodoniBold(size: 18))
                .foregroundColor(Colors.primaryDark)
            
            VStack(spacing: 8) {
                ForEach(Array(results.enumerated()), id: \.offset) { _, result in
                    HStack {
                        Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(result.success ? .green : .red)
                        
                        Text(result.phoneNumber)
                            .font(.LibreBodoni(size: 14))
                            .foregroundColor(Colors.k292929)
                        
                        if !result.success, let error = result.error {
                            Text("• \(error)")
                                .font(.LibreBodoni(size: 12))
                                .foregroundColor(.red)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(result.success ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                    )
                }
            }
        }
    }
}

#Preview {
    SendInvitesView(
        coveId: "preview-cove-id",
        coveName: "San Francisco Tech Meetup",
        sendAction: nil,
        onDataSubmit: nil,
        initialPhoneNumbers: [],
        initialMessage: ""
    )
} 