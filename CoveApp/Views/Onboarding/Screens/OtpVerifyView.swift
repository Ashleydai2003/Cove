//
//  OtpVerifyView.swift
//  Cove
//

// TODO: allow backspace when field is empty

import SwiftUI

/// View for handling OTP (One-Time Password) verification during user onboarding
/// Manages a 5-digit verification code input with automatic field advancement
struct OtpVerifyView: View {
    // MARK: - Properties
    
    /// App controller for managing navigation and shared state
    @EnvironmentObject var appController: AppController
    
    /// Array to store individual digits of the OTP
    /// Initialized with 5 empty strings for each digit position
    @State private var otp: [String] = Array(repeating: "", count: 5)
    
    /// Tracks which OTP input field is currently focused
    /// Used for automatic field advancement and keyboard management
    @FocusState private var focusedIndex: Int?
    
    // MARK: - Computed Properties
    
    /// Formats the phone number with hyphens for display
    private var formattedPhoneNumber: String {
        let digits = appController.phoneNumber.filter { $0.isNumber }
        if digits.count == 10 {
            let areaCode = String(digits.prefix(3))
            let middle = String(digits[digits.index(digits.startIndex, offsetBy: 3)..<digits.index(digits.startIndex, offsetBy: 6)])
            let last = String(digits.suffix(4))
            return "\(areaCode)-\(middle)-\(last)"
        }
        return appController.phoneNumber
    }
    
    // MARK: - View Body
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                
                VStack {
                    // MARK: - Navigation Header
                    HStack {
                        Button {
                            appController.path.removeLast()
                        } label: {
                            Images.backArrow
                        }
                        Spacer()
                    }
                    .padding(.top, 10)
                    
                    // MARK: - Title and Phone Number Section
                    VStack(alignment: .leading) {
                        Text("enter your \nverification code")
                            .foregroundStyle(Colors.primaryDark)
                            .font(.LibreBodoni(size: 40))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Phone number display with edit option
                        HStack(spacing: 0) {
                            Text("sent to \(formattedPhoneNumber) | ")
                                .foregroundStyle(Colors.primaryDark)
                                .font(.LeagueSpartan(size: 15))
                            
                            Button {
                                appController.path.removeLast()
                            } label: {
                                Text("edit number")
                                    .foregroundStyle(Colors.primaryDark)
                                    .font(.LeagueSpartan(size: 15))
                            }
                        }
                    }
                    .padding(.top, 40)
                    
                    // MARK: - OTP Input Fields
                    HStack(spacing: 10) {
                        ForEach(0..<otp.count, id: \.self) { index in
                            VStack {
                                TextField("", text: $otp[index])
                                    .keyboardType(.numberPad)
                                    .foregroundStyle(Color.black)
                                    .multilineTextAlignment(.center)
                                    .font(.LibreCaslon(size: 40))
                                    .focused($focusedIndex, equals: index)
                                    // Add this modifier to prevent unwanted input
                                    .textContentType(.oneTimeCode)
                                    .onChange(of: otp[index]) { oldValue, newValue in
                                        // Only proceed if the new value is either empty or a single number
                                        if newValue.isEmpty || (newValue.count == 1 && newValue.first?.isNumber == true) {
                                            // Keep the value as is
                                            if !newValue.isEmpty && index < 4 {
                                                focusedIndex = index + 1  // Move to next field
                                            } else if newValue.isEmpty && index > 0 {
                                                focusedIndex = index - 1  // Move to previous field
                                            }
                                        } else {
                                            // Revert to old value if invalid input
                                            otp[index] = oldValue
                                        }
                                        
                                        // Check if all fields are filled and navigate if complete
                                        let enteredAllCode = otp.allSatisfy { !$0.isEmpty }
                                        if enteredAllCode {
                                            appController.path.append(.userDetails)
                                        }
                                    }
                                
                                // Bottom divider for each input field
                                Divider()
                                    .frame(height: 2)
                                    .background(Color.black.opacity(0.58))
                            }
                        }
                    }
                    .padding(.top, 50)
                    
                    // MARK: - Resend Code Button
                    HStack {
                        Spacer()
                        Button {
                            // TODO: Implement resend code functionality
                        } label: {
                            Text("resend code")
                                .foregroundStyle(Colors.primaryDark)
                                .font(.LeagueSpartan(size: 15))
                        }
                    }
                    .padding(.top, 5)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .safeAreaPadding()
            }
        }
        .navigationBarBackButtonHidden()  // Hide default back button to prevent accidental navigation
        // Focus on the first input field when the view appears
        .onAppear {
            focusedIndex = 0
        }
    }
}

// MARK: - Preview
#Preview {
    OtpVerifyView()
        .environmentObject(AppController.shared)
}
