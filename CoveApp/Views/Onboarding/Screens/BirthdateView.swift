//
//  BirthdateView.swift
//  Cove
//  Created by Ananya Agarwal
//  Created by Sheng Moua on 4/21/25.
//

// TODO: there's a bug when i change the year to be correct but the date and the month are still incorrect, it moves me onto the next screen

import SwiftUI

/// A view that handles user birthdate input during the onboarding process.
/// Features:
/// - Separate input fields for month, day, and year
/// - Input validation for month and day
/// - Custom styling with diagonal separators
/// - Navigation controls for the onboarding flow
struct BirthdateView: View {
    
    // MARK: - Properties
    
    /// App controller for managing navigation and app state
    @EnvironmentObject var appController: AppController
    
    /// Single string to store the complete birthdate (MMDDYYYY format)
    @State private var birthdateText: String = ""
    @State private var errorMessage: String = ""
    
    /// Tracks if the hidden input field is focused
    @FocusState private var isInputFocused: Bool
    
    /// Computed properties to extract individual components for display
    private var monthDisplay: String {
        let digits = Array(birthdateText).map(String.init)
        if digits.count >= 2 {
            return digits[0] + digits[1]
        } else if digits.count >= 1 {
            return digits[0]
        }
        return ""
    }
    
    private var dayDisplay: String {
        let digits = Array(birthdateText).map(String.init)
        if digits.count >= 4 {
            return digits[2] + digits[3]
        } else if digits.count >= 3 {
            return digits[2]
        }
        return ""
    }
    
    private var yearDisplay: String {
        let digits = Array(birthdateText).map(String.init)
        if digits.count >= 8 {
            return digits[4] + digits[5] + digits[6] + digits[7]
        } else if digits.count >= 7 {
            return digits[4] + digits[5] + digits[6]
        } else if digits.count >= 6 {
            return digits[4] + digits[5]
        } else if digits.count >= 5 {
            return digits[4]
        }
        return ""
    }
    
    /// Computed property to check if all fields are filled
    private var isBirthdateComplete: Bool {
        birthdateText.count == 8
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            VStack {
                // Back button
                HStack {
                    Button {
                        appController.path.removeLast()
                    } label: {
                        Images.backArrow
                    }
                    Spacer()
                }
                .padding(.top, 10)
                
                // Header text
                VStack(alignment: .leading) {
                    Text("when's your \nbirthday?")
                        .foregroundStyle(Colors.primaryDark)
                        .font(.LibreBodoni(size: 40))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
            

                    Text("only your age will be displayed on your profile")
                        .foregroundStyle(Colors.primaryDark)
                        .font(.LeagueSpartan(size: 15))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.top, 40)
                
                // Birthdate input fields
                VStack(spacing: 8) {
                    ZStack {
                        // Hidden TextField for actual input
                        TextField("", text: $birthdateText)
                            .keyboardType(.numberPad)
                            .focused($isInputFocused)
                            .opacity(0)
                            .onChange(of: birthdateText) { oldValue, newValue in
                                handleBirthdateInput(oldValue: oldValue, newValue: newValue)
                            }
                        
                        // Visual representation of birthdate fields
                        HStack(spacing: 10) {
                            Spacer()
                            
                            // Month display
                            VStack(alignment: .center) {
                                Text(monthDisplay.isEmpty ? "mm" : monthDisplay)
                                    .foregroundStyle(monthDisplay.isEmpty ? Color.gray : Color.black)
                                    .multilineTextAlignment(.center)
                                    .font(.LibreCaslon(size: 24))
                                    .frame(width: 60, height: 30)
                            }
                            
                            Text("/")
                                .font(.LibreCaslon(size: 24))
                                .foregroundStyle(Color.black)
                            
                            // Day display
                            VStack {
                                Text(dayDisplay.isEmpty ? "dd" : dayDisplay)
                                    .foregroundStyle(dayDisplay.isEmpty ? Color.gray : Color.black)
                                    .multilineTextAlignment(.center)
                                    .font(.LibreCaslon(size: 24))
                                    .frame(width: 60, height: 30)
                            }
                            
                            Text("/")
                                .font(.LibreCaslon(size: 24))
                                .foregroundStyle(Color.black)
                            
                            // Year display
                            VStack {
                                Text(yearDisplay.isEmpty ? "yyyy" : yearDisplay)
                                    .foregroundStyle(yearDisplay.isEmpty ? Color.gray : Color.black)
                                    .multilineTextAlignment(.center)
                                    .font(.LibreCaslon(size: 24))
                                    .frame(width: 80, height: 30)
                            }
                            
                            Spacer()
                        }
                        .onTapGesture {
                            isInputFocused = true
                        }
                    }
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundStyle(Color.red)
                            .font(.LibreBodoni(size: 14))
                    }
                }
                .padding(.top, 50)
                
                Spacer()
                
            }
            .padding(.horizontal, 20)
            .safeAreaPadding()
        }
        .navigationBarBackButtonHidden()
        .onAppear {
            isInputFocused = true
        }
    }
    
    // MARK: - Helper Methods
    
    /// Handles birthdate input with improved focus management and backspace behavior
    private func handleBirthdateInput(oldValue: String, newValue: String) {
        // Clear error when editing
        errorMessage = ""
        
        // Limit to 8 digits maximum (MMDDYYYY)
        if newValue.count > 8 {
            birthdateText = String(newValue.prefix(8))
            return
        }
        
        // Only allow numeric input
        let filtered = newValue.filter { $0.isNumber }
        if filtered != newValue {
            birthdateText = filtered
            return
        }
        
        // Auto-validate when all 8 digits are entered
        if newValue.count == 8 {
            validateBirthdate()
        }
    }
    
    /// Validates the complete birthdate
    private func validateBirthdate() {
        // Extract month, day, year from birthdateText (MMDDYYYY format)
        guard birthdateText.count == 8 else {
            errorMessage = "enter a valid birthdate"
            return
        }
        
        let monthString = String(birthdateText.prefix(2))
        let dayString = String(birthdateText.dropFirst(2).prefix(2))
        let yearString = String(birthdateText.suffix(4))
        
        guard let monthInt = Int(monthString),
              let dayInt = Int(dayString),
              let yearInt = Int(yearString) else {
            errorMessage = "enter a valid birthdate"
            return
        }
        
        // Validate month is between 1-12
        guard monthInt >= 1 && monthInt <= 12 else {
            errorMessage = "enter a valid birthdate"
            return
        }
        
        // Validate day is between 1-31 (basic check)
        guard dayInt >= 1 && dayInt <= 31 else {
            errorMessage = "enter a valid birthdate"
            return
        }
        
        // Check if year is reasonable (not in future and not too old)
        let currentYear = Calendar.current.component(.year, from: Date())
        guard yearInt <= currentYear && yearInt >= currentYear - 120 else {
            errorMessage = "enter a valid birthdate"
            return
        }
        
        // Create date components and validate the date actually exists
        var dateComponents = DateComponents()
        dateComponents.year = yearInt
        dateComponents.month = monthInt
        dateComponents.day = dayInt
        
        // Convert DateComponents to Date - this will return nil for invalid dates like Feb 30th
        guard let birthDate = Calendar.current.date(from: dateComponents) else {
            errorMessage = "enter a valid birthdate"
            return
        }
        
        // Verify the created date matches what we input (handles cases like Feb 30 -> Mar 2)
        let calendar = Calendar.current
        let createdMonth = calendar.component(.month, from: birthDate)
        let createdDay = calendar.component(.day, from: birthDate)
        let createdYear = calendar.component(.year, from: birthDate)
        
        guard createdMonth == monthInt && createdDay == dayInt && createdYear == yearInt else {
            errorMessage = "enter a valid birthdate"
            return
        }
        
        // Check if user is at least 18 years old
        let today = Date()
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: today)
        guard let age = ageComponents.year, age >= 18 else {
            errorMessage = "you must be at least 18 years old"
            return
        }
        
        // If we get here, the date is valid and user is over 18
        errorMessage = ""
        // TODO: We should still use the smiley as the next button 
        // Store the Date object in UserDefaults
        Onboarding.storeBirthdate(birthDate: birthDate)
        // Navigate to next screen
        appController.path.append(.userLocation)
    }
}

// MARK: - Preview
#Preview {
    BirthdateView()
        .environmentObject(AppController.shared)
}
