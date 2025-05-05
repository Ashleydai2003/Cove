//
//  UserPhoneNumberView.swift
//  Cove
//

import SwiftUI
import Combine

struct UserPhoneNumberView: View {
    
    // Environment object to access shared app controller
    @EnvironmentObject var appController: AppController
    
    // State variables for managing UI state
    @State private var presentSheet = false // Controls country selection sheet visibility
    @State private var searchCountry: String = "" // Search text for country filtering
    @FocusState private var isFocused: Bool // Tracks phone number field focus
    @State private var isVerifying = false // Indicates verification process status
    @State private var showError = false // Controls error alert visibility
    
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
        .background(Color(.systemGray6))
    }
    
    // Load country data from JSON file
    let counrties: [Country] = Bundle.main.decode("CountryList.json")
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background image with reduced opacity
                OnboardingBackgroundView(imageName: "phoneNumber_background")
                    .opacity(0.4)
                
                VStack {
                    // Title and description section
                    VStack(alignment: .leading, spacing: 5) {
                        Text("what's your phone \nnumber?")
                            .foregroundStyle(Colors.primaryDark)
                            .font(.LibreBodoni(size: 40))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text("verification code will be sent to the following number. message and data rates may apply.")
                            .foregroundStyle(Color.black)
                            .font(.LeagueSpartan(size: 15))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.top, 40)
                    
                    // Phone number input section with country code selector
                    HStack(alignment: .lastTextBaseline, spacing: 16) {
                        // Country code selector button
                        VStack(spacing: 2) {
                            Button {
                                presentSheet = true
                            } label: {
                                HStack {
                                    Text(appController.selectedCountry.flag)
                                        .foregroundStyle(Color.black)
                                        .font(.LibreBodoni(size: 30))
                                    
                                    Images.downArrowSolid
                                        .resizable()
                                        .frame(width: 19, height: 14)
                                }
                            }
                            
                            Divider()
                                .frame(height: 2)
                                .background(Color.black.opacity(0.58))
                        }
                        .frame(width: 66)
                        
                        // Phone number input field
                        VStack(spacing: 2) {
                            HStack {
                                Text(appController.selectedCountry.dial_code)
                                    .foregroundStyle(Color.black)
                                    .font(.LibreCaslon(size: 25))
                                
                                TextField(appController.selectedCountry.pattern, text: $appController.phoneNumber)
                                    .font(.LibreCaslon(size: 25))
                                    .foregroundStyle(Color.black)
                                    .keyboardType(.numberPad)
                                    .focused($isFocused)
                                    .onChange(of: appController.phoneNumber) { _, newValue in
                                        appController.phoneNumber = appController.formatPhoneNumber(newValue, pattern: appController.selectedCountry.pattern)
                                    }
                                    .toolbar {
                                        ToolbarItem(placement: .keyboard) {
                                            keyboardAccessoryView
                                        }
                                    }
                            }
                            
                            Divider()
                                .frame(height: 2)
                                .background(Color.black.opacity(0.58))
                        }
                    }
                    .padding(.top, 85)
                    
                    Spacer()
                    
                    // Submit button (smiley icon)
                    HStack {
                        Spacer()
                        Images.smily
                            .resizable()
                            .frame(width: 52, height: 52)
                            .padding(.init(top: 0, leading: 0, bottom: 60, trailing: 20))
                            .onTapGesture {
                                if appController.isValidPhoneNumber(appController.phoneNumber, pattern: appController.selectedCountry.pattern) {
                                    sendVerificationCode()
                                }
                            }
                    }
                }
                .padding(.horizontal, 20)
                .safeAreaPadding()
                // Error alert
                .alert("Error", isPresented: $showError) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text(appController.errorMessage)
                }
            }
            // Country selection sheet
            .sheet(isPresented: $presentSheet) {
                NavigationView {
                    List(filteredResorts) { country in
                        Button {
                            appController.selectedCountry = country
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
        }
        .navigationBarBackButtonHidden()
    }
    
    // Sends verification code to the entered phone number
    private func sendVerificationCode() {
        isVerifying = true
        appController.sendVerificationCode { success in
            isVerifying = false
            if success {
                appController.path.append(.otpVerify)
            } else {
                showError = true
            }
        }
    }
    
    // Filters countries based on search text
    var filteredResorts: [Country] {
        if searchCountry.isEmpty {
            return counrties
        } else {
            return counrties.filter { $0.name.localizedCaseInsensitiveContains(searchCountry) }
        }
    }
}

#Preview {
    UserPhoneNumberView()
        .environmentObject(AppController.shared)
}
