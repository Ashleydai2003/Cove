//
//  UserPhoneNumberView.swift
//  Cove
//

import SwiftUI
import Combine
import Inject

/// View for collecting and validating user's phone number during onboarding
/// Handles country selection, phone number formatting, and navigation to OTP verification
struct UserPhoneNumberView: View {
    @ObserveInjection var redraw
    
    // MARK: - Environment & State Properties
    
    /// App controller for managing navigation and shared state
    @EnvironmentObject var appController: AppController
    
    /// UI State
    @State private var presentSheet = false
    @State private var searchCountry: String = ""
    @FocusState private var isFocused: Bool
    @State private var hasNavigated: Bool = false
    
    /// Data
    let counrties: [Country] = Bundle.main.decode("CountryList.json")
    
    // MARK: - Helper Methods
    
    /// Validates if the phone number matches the expected length for the selected country
    private func checkPhoneNumberCompletion(_ number: String) -> Bool {
        let digitsOnly = number.filter { $0.isNumber }
        let expectedLength = appController.selectedCountry.pattern.filter { $0 == "#" }.count
        return digitsOnly.count == expectedLength
    }
    
    // MARK: - Main View Body
    
    var body: some View {
        GeometryReader { _ in
            ZStack {
                VStack {
                    // MARK: - Header Section
                    VStack(alignment: .leading, spacing: 5) {
                        Text("what's your phone number?")
                            .foregroundStyle(Colors.primaryDark)
                            .font(.LibreBodoni(size: 40))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text("verification code will be sent to the following number. message and data rates may apply.")
                            .foregroundStyle(Color.black)
                            .font(.LeagueSpartan(size: 15))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.top, 40)
                    .enableInjection()
                    
                    // MARK: - Phone Number Input Section
                    HStack(alignment: .lastTextBaseline, spacing: 16) {
                        // Country Selection Button
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
                        .frame(width: 66)
                        
                        // Phone Number Input Field
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
                                    let formattedNumber = appController.formatPhoneNumber(newValue, pattern: appController.selectedCountry.pattern)
                                    appController.phoneNumber = formattedNumber
                                    if checkPhoneNumberCompletion(formattedNumber) && !hasNavigated {
                                        hasNavigated = true
                                        appController.path.append(.otpVerify)
                                    }
                                }
                        }
                    }
                    .padding(.top, 85)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .safeAreaPadding()
            }
            
            // MARK: - Country Selection Sheet
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
        .onDisappear {
            hasNavigated = false
        }
        .onAppear {
            isFocused = true
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
}

// MARK: - Preview
#Preview {
    UserPhoneNumberView()
        .environmentObject(AppController.shared)
}
