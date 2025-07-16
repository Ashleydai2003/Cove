//
//  UserPhoneNumberView.swift
//  Cove
//
//  Created by Nesib Muhedin

import SwiftUI
import Combine

/// View for collecting and validating user's phone number during onboarding
/// Handles country selection, phone number formatting, and navigation to OTP verification
struct UserPhoneNumberView: View {

    
    // MARK: - Environment & State Properties
    
    /// App controller for managing navigation and shared state
    @EnvironmentObject var appController: AppController
    
    /// UI State
    @State private var presentSheet = false
    @State private var searchCountry: String = ""
    @FocusState private var isFocused: Bool
    @State private var isCodeSending = false
    @State private var showError = false
    @State private var userPhone = UserPhoneNumber(number: "",country: Country(id: "0235", name: "USA", flag: "🇺🇸", code: "US", dial_code: "+1", pattern: "### ### ####", limit: 17))
    
    // Status messaging
    @State private var statusMessage: String = ""
    @State private var messageType: MessageType = .none
    
    enum MessageType {
        case none
        case success
        case error
    }
    
    // MARK: - Constants
    
    private enum Constants {
        static let titleFontSize: CGFloat = 40
        static let subtitleFontSize: CGFloat = 15
        static let phoneInputFontSize: CGFloat = 25
        static let countryButtonWidth: CGFloat = 66
        static let countryFlagFontSize: CGFloat = 30
        static let downArrowSize: CGSize = .init(width: 19, height: 14)
        static let arrowSize: CGSize = .init(width: 52, height: 52)
        static let horizontalPadding: CGFloat = 20
        static let topPadding: CGFloat = 40
        static let phoneInputTopPadding: CGFloat = 85
        static let arrowBottomPadding: CGFloat = 60
        static let arrowTrailingPadding: CGFloat = 20
    }
    
    // Custom input accessory view for keyboard
    private var keyboardAccessoryView: some View {
        HStack {
            Spacer()
            Button("Done") {
                isFocused = false
            }
            .padding(.trailing, 16)
            .padding(.vertical, 8)
        }
        .background(Color.gray.opacity(0.1))
    }
    
    /// Data
    let counrties: [Country] = Bundle.main.decode("CountryList.json")
    
    // MARK: - Helper Methods
    
    /// Validates if the phone number matches the expected length for the selected country
    private func checkPhoneNumberCompletion(_ number: String) -> Bool {
        let digitsOnly = number.filter { $0.isNumber }
        let expectedLength = userPhone.country.pattern.filter { $0 == "#" }.count
        return digitsOnly.count == expectedLength
    }
    
    // MARK: - Status Message Display
    
    private var statusMessageView: some View {
        HStack {
            if !statusMessage.isEmpty {
                Text(statusMessage)
                    .font(.LeagueSpartan(size: 14))
                    .foregroundColor(messageType == .success ? .green : 
                                   messageType == .error ? .red : Colors.primaryDark)
            }
            Spacer()
        }
        .padding(.horizontal, Constants.horizontalPadding)
        .padding(.top, 8)
        .animation(.easeInOut(duration: 0.3), value: statusMessage)
    }
    
    // MARK: - Main View Body
    var body: some View {
        ZStack {
            OnboardingBackgroundView()
            VStack {
                // MARK: - Header Section
                headerSection
                
                // MARK: - Phone Number Input Section
                HStack(alignment: .lastTextBaseline, spacing: 16) {
                    // Country Selection Button
                    countrySelectionButton
                    
                    // Phone Number Input Field
                    phoneNumberInputField
                }
                .padding(.top, Constants.phoneInputTopPadding)
                
                // MARK: - Status Message
                statusMessageView
                
                Spacer()
                
                // MARK: - Submit Button
                //submitButton
            }
            .padding(.horizontal, Constants.horizontalPadding)
            .safeAreaPadding()
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(appController.errorMessage)
            }
        }
        // MARK: - Country Selection Sheet
        .sheet(isPresented: $presentSheet) {
            NavigationView {
                List {
                    ForEach(filteredResorts, id: \.id) { country in
                        HStack {
                            Text(country.flag)
                                .font(.system(size: Constants.countryFlagFontSize))
                            Text(country.name)
                                .font(.LeagueSpartan(size: 16))
                            Spacer()
                            Text(country.dial_code)
                                .font(.LeagueSpartan(size: 16))
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            userPhone.country = country
                            presentSheet = false
                        }
                    }
                }
                .listStyle(PlainListStyle())
                .navigationTitle("Select Country")
                .navigationBarTitleDisplayMode(.inline)
                .searchable(text: $searchCountry, prompt: "Search country")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            presentSheet = false
                        }
                    }
                }
            }
        }
        .onAppear {
            // Auto-focus on phone number input
            isFocused = true
            
            // Auto-send code if phone number is complete when returning from OTP screen
            if checkPhoneNumberCompletion(userPhone.number) && statusMessage.isEmpty {
                sendVerificationCodeWithFeedback()
            }
        }
    }
    
    // MARK: - View Components
    
    /// Header section with title and subtitle
    var headerSection: some View {
        VStack(alignment: .leading) {
            Text("enter your \nphone number")
                .foregroundStyle(Colors.primaryDark)
                .font(.LibreBodoni(size: Constants.titleFontSize))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text("we'll send you a verification code")
                .foregroundStyle(Colors.primaryDark)
                .font(.LeagueSpartan(size: Constants.subtitleFontSize))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.top, Constants.topPadding)
    }
    
    /// Country selection button
    var countrySelectionButton: some View {
        Button {
            presentSheet = true
        } label: {
            HStack(spacing: 8) {
                Text(userPhone.country.flag)
                    .font(.system(size: Constants.countryFlagFontSize))
                Images.downArrowSolid
                    .resizable()
                    .frame(width: Constants.downArrowSize.width, 
                            height: Constants.downArrowSize.height)
            }
            .frame(width: Constants.countryButtonWidth)
        }
        .toolbar {
            ToolbarItem(placement: .keyboard) {
                keyboardAccessoryView
            }
        }
    }
    
    /// Phone number input field
    var phoneNumberInputField: some View {
        HStack {
            Text(userPhone.country.dial_code)
                .foregroundStyle(Color.black)
                .font(.LibreCaslon(size: Constants.phoneInputFontSize))
            
            TextField(userPhone.country.pattern, text: $userPhone.number)
                .font(.LibreCaslon(size: Constants.phoneInputFontSize))
                .foregroundStyle(Color.black)
                .keyboardType(.numberPad)
                .focused($isFocused)
                .textContentType(.telephoneNumber)
                .tint(.clear) // Hide cursor
                .onChange(of: userPhone.number) { _, newValue in
                    let formattedNumber = userPhone.formatPhoneNumber(newValue, pattern: userPhone.country.pattern)
                    userPhone.number = formattedNumber
                    
                    // Only clear messages if we're not in the middle of sending
                    if !isCodeSending {
                        statusMessage = ""
                        messageType = .none
                    }
                    
                    // Send verification code when number is complete
                    if checkPhoneNumberCompletion(formattedNumber) && !isCodeSending {
                        sendVerificationCodeWithFeedback()
                    }
                }
        }
    }

    // MARK: - Computed Properties
    /// Filters countries based on search input
    var filteredResorts: [Country] {
        if searchCountry.isEmpty {
            return counrties
        } else {
            return counrties.filter { $0.name.localizedCaseInsensitiveContains(searchCountry) }
        }
    }
    
    // MARK: - Private Methods
    private func sendVerificationCodeWithFeedback() {
        guard !isCodeSending else { return }
        
        isCodeSending = true
        statusMessage = "Sending code..."
        messageType = .none
        
        userPhone.sendVerificationCode { result in
            isCodeSending = false
            
            switch result {
            case .success:
                statusMessage = "Code sent!"
                messageType = .success
                // Navigate to OTP view
                appController.path.append(.otpVerify)
                
            case .invalidPhoneNumber:
                statusMessage = "Failure to send code, check that your phone number is correct."
                messageType = .error
                
            case .networkError:
                statusMessage = "Network error. Please check your connection and try again."
                messageType = .error
                
            case .rateLimited:
                statusMessage = "Wait just a few seconds and try to resend again."
                messageType = .error
                
            case .unknownError(_):
                statusMessage = "Code failed to send—try another phone number."
                messageType = .error
            }
        }
    }
}

// MARK: - Preview
#Preview {
    UserPhoneNumberView()
        .environmentObject(AppController.shared)
}
