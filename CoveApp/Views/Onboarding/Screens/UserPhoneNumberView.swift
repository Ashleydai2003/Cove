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
    @State private var isVerifying = false
    @State private var showError = false
    @State private var userPhone = UserPhoneNumber(number: "",country: Country(id: "0235", name: "USA", flag: "🇺🇸", code: "US", dial_code: "+1", pattern: "### ### ####", limit: 17))
    
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
                List(filteredResorts) { country in
                    Button {
                        // Clear the phone number if it's not valid for the new country
                        let currentDigits = userPhone.number.filter { $0.isNumber }
                        let newCountryMaxDigits = country.pattern.filter { $0 == "#" }.count
                        
                        // If current number has more digits than new country allows, clear it
                        if currentDigits.count > newCountryMaxDigits {
                            userPhone.number = ""
                        }
                        
                        userPhone.country = country
                        presentSheet = false
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
        .navigationBarBackButtonHidden()
        .onAppear {
            isFocused = true
        }
    }

    // MARK: - View Components
    // Header Section
    var headerSection: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("what's your phone number?")
                .foregroundStyle(Colors.primaryDark)
                .font(.LibreBodoni(size: Constants.titleFontSize))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text("verification code will be sent to the following number. message and data rates may apply.")
                .foregroundStyle(Color.black)
                .font(.LeagueSpartan(size: Constants.subtitleFontSize))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.top, Constants.topPadding)
        .enableInjection()
    }

    // Country Selection Button
    var countrySelectionButton: some View {
        Button {
            presentSheet = true
        } label: {
            HStack {
                Text(userPhone.country.flag)
                    .foregroundStyle(Color.black)
                    .font(.LibreBodoni(size: Constants.countryFlagFontSize))
                
                Images.downArrowSolid
                    .resizable()
                    .frame(width: Constants.downArrowSize.width, 
                            height: Constants.downArrowSize.height)
            }
        }
        .frame(width: Constants.countryButtonWidth)
    }

    // Phone Number Input Field
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
                .toolbar {
                    ToolbarItem(placement: .keyboard) {
                        keyboardAccessoryView
                    }
                }
                .onChange(of: userPhone.number) { _, newValue in
                    let formattedNumber = userPhone.formatPhoneNumber(newValue, pattern: userPhone.country.pattern)
                    userPhone.number = formattedNumber
                    
                    // Send verification code when number is complete
                    if checkPhoneNumberCompletion(formattedNumber) && !isVerifying {
                        sendVerificationCode()
                    }
                }
        }
    }

    // // Submit Button
    // var submitButton: some View {
    //     HStack {
    //         Spacer()
    //         Images.nextArrow
    //             .resizable()
    //             .frame(width: Constants.arrowSize.width, 
    //                     height: Constants.arrowSize.height)
    //             .padding(EdgeInsets(top: 0, 
    //                                 leading: 0, 
    //                                 bottom: Constants.arrowBottomPadding, 
    //                                 trailing: Constants.arrowTrailingPadding))
    //             .onTapGesture {
    //                 if userPhone.isValidPhoneNumber(userPhone.number, pattern: userPhone.country.pattern) {
    //                     appController.path.append(.otpVerify)
    //                 }
    //             }
    //     }
    // }

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
    private func sendVerificationCode() {
        guard !isVerifying else { return }
        isVerifying = true
        
        userPhone.sendVerificationCode { success in
            isVerifying = false
            if success {
                // Automatically navigate to OTP verification screen
                appController.path.append(.otpVerify)
            } else {
                showError = true
            }
        }
    }
}

// MARK: - Preview
#Preview {
    UserPhoneNumberView()
        .environmentObject(AppController.shared)
}
