//
//  BirthdateView.swift
//  Cove
//
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
    
    /// State variables for birthdate components
    @State private var date: String = ""
    @State private var month: String = ""
    @State private var year: String = ""
    @State private var errorMessage: String = ""
    
    /// Focus states for each field
    @FocusState private var isMonthFocused: Bool
    @FocusState private var isDayFocused: Bool
    @FocusState private var isYearFocused: Bool
    
    /// Computed property to check if all fields are filled
    private var isBirthdateComplete: Bool {
        month.count == 2 && date.count == 2 && year.count == 4
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
                    HStack(spacing: 10) {
                        Spacer()
                        
                        // Month input
                        VStack(alignment: .center) {
                            TextField("mm", text: $month)
                                .keyboardType(.numberPad)
                                .foregroundStyle(Color.black)
                                .multilineTextAlignment(.center)
                                .font(.LibreCaslon(size: 24))
                                .focused($isMonthFocused)
                                .onChange(of: month) { oldValue, newValue in
                                    validateMonth(newValue, oldValue: oldValue)
                                }
                        }
                        
                        Images.lineDiagonal
                        
                        // Day input
                        VStack {
                            TextField("dd", text: $date)
                                .keyboardType(.numberPad)
                                .foregroundStyle(Color.black)
                                .multilineTextAlignment(.center)
                                .font(.LibreCaslon(size: 24))
                                .focused($isDayFocused)
                                .onChange(of: date) { oldValue, newValue in
                                    validateDate(newValue, oldValue: oldValue)
                                }
                        }
                        
                        Images.lineDiagonal
                        
                        // Year input
                        VStack {
                            TextField("yyyy", text: $year)
                                .keyboardType(.numberPad)
                                .foregroundStyle(Color.black)
                                .multilineTextAlignment(.center)
                                .font(.LibreCaslon(size: 24))
                                .focused($isYearFocused)
                                .onChange(of: year) { oldValue, newValue in
                                    validateYear(newValue, oldValue: oldValue)
                                    if isBirthdateComplete {
                                        validateBirthdate()
                                    }
                                }
                        }
                        
                        Spacer()
                    }
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundStyle(Colors.primaryDark)
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
            isMonthFocused = true
        }
    }
    
    // MARK: - Helper Methods
    
    /// Validates and formats the month input
    /// - Parameters:
    ///   - newValue: The new input value
    ///   - oldValue: The previous input value
    private func validateMonth(_ newValue: String, oldValue: String) {
        if newValue.isEmpty { return }
        
        errorMessage = "" // Clear error when editing
        let filtered = newValue.filter { $0.isNumber }
        if filtered.count >= 2 {
            month = String(filtered.prefix(2))
            isMonthFocused = false
            isDayFocused = true
        } else {
            month = filtered
        }
    }
    
    /// Validates and formats the day input
    /// - Parameters:
    ///   - newValue: The new input value
    ///   - oldValue: The previous input value
    private func validateDate(_ newValue: String, oldValue: String) {
        if newValue.isEmpty { return }
        
        errorMessage = "" // Clear error when editing
        let filtered = newValue.filter { $0.isNumber }
        if filtered.count >= 2 {
            date = String(filtered.prefix(2))
            isDayFocused = false
            isYearFocused = true
        } else {
            date = filtered
        }
    }
    
    /// Validates and formats the year input
    /// - Parameters:
    ///   - newValue: The new input value
    ///   - oldValue: The previous input value
    private func validateYear(_ newValue: String, oldValue: String) {
        if newValue.isEmpty { return }
        
        errorMessage = "" // Clear error when editing
        let filtered = newValue.filter { $0.isNumber }
        if filtered.count >= 4 {
            year = String(filtered.prefix(4))
        } else {
            year = filtered
        }
    }
    
    /// Validates the complete birthdate
    private func validateBirthdate() {
        guard let monthInt = Int(month),
              let dayInt = Int(date),
              let yearInt = Int(year) else {
            errorMessage = "enter a valid birthdate"
            return
        }
        
        // Check if year is reasonable (not in future and not too old)
        let currentYear = Calendar.current.component(.year, from: Date())
        guard yearInt <= currentYear && yearInt >= currentYear - 120 else {
            errorMessage = "enter a valid birthdate"
            return
        }
        
        // Create date components and validate
        var dateComponents = DateComponents()
        dateComponents.year = yearInt
        dateComponents.month = monthInt
        dateComponents.day = dayInt
        
        
        // TODO: See Xcode Warning
        guard let calendar = Calendar.current.date(from: dateComponents) else {
            errorMessage = "enter a valid birthdate"
            return
        }
        
        // If we get here, the date is valid
        errorMessage = ""
        // Navigate to next screen
        appController.path.append(OnboardingRoute.hobbies)
    }
}

// MARK: - Preview
#Preview {
    BirthdateView()
        .environmentObject(AppController.shared)
}
