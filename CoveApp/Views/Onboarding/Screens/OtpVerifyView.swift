//
//  OtpVerifyView.swift
//  Cove
//
//  Created by Ananya Agarwal

// TODO: allow backspace when field is empty

import SwiftUI

/// View for handling OTP (One-Time Password) verification during user onboarding
/// Manages a 5-digit verification code input with automatic field advancement
struct OtpVerifyView: View {
    // MARK: - Properties
    
    /// App controller for managing navigation and shared state
    @EnvironmentObject var appController: AppController
    
    /// Single string to store the complete OTP
    @State private var otpText: String = ""
    
    /// Tracks if the hidden input field is focused
    @FocusState private var isInputFocused: Bool
    
    /// Computed property to get individual digits for display
    private var otpDigits: [String] {
        let digits = Array(otpText).map(String.init)
        let paddedDigits = digits + Array(repeating: "", count: max(0, 6 - digits.count))
        return Array(paddedDigits.prefix(6))
    }
    
    /// Tracks whether the OTP verification process is in progress
    @State private var isVerifying = false
    
    /// Tracks whether an error should be shown
    @State private var showError = false
    
    // Custom input accessory view for keyboard
    private var keyboardAccessoryView: some View {
        HStack {
            Spacer()
            Button("Done") {
                isInputFocused = false
            }
            .padding(.trailing, 16)
            .padding(.vertical, 8)
        }
        .background(Color.gray.opacity(0.1))
    }
    
    // MARK: - Computed Properties
    
    /// Formats the phone number with hyphens for display
    private var formattedPhoneNumber: String {
        let phoneNumber = UserDefaults.standard.string(forKey: "UserPhoneNumber") ?? ""
        let digits = phoneNumber.filter { $0.isNumber }
        if digits.count == 10 {
            let areaCode = String(digits.prefix(3))
            let middle = String(digits[digits.index(digits.startIndex, offsetBy: 3)..<digits.index(digits.startIndex, offsetBy: 6)])
            let last = String(digits.suffix(4))
            return "\(areaCode)-\(middle)-\(last)"
        }
        return phoneNumber
    }
    
    // MARK: - View Body
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                OnboardingBackgroundView()
                
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
                                OtpVerify.handleAuthFailure()
                            } label: {
                                Text("edit number")
                                    .foregroundStyle(Colors.primaryDark)
                                    .font(.LeagueSpartan(size: 15))
                            }
                        }
                    }
                    .padding(.top, 40)
                    
                    // MARK: - OTP Input Fields
                    ZStack {
                        // Hidden TextField for actual input
                        TextField("", text: $otpText)
                            .keyboardType(.numberPad)
                            .textContentType(.oneTimeCode)
                            .focused($isInputFocused)
                            .opacity(0)
                            .disabled(isVerifying)
                            .toolbar {
                                ToolbarItem(placement: .keyboard) {
                                    keyboardAccessoryView
                                }
                            }
                            .onChange(of: otpText) { oldValue, newValue in
                                handleOTPInput(oldValue: oldValue, newValue: newValue)
                            }
                        
                        // Visual representation of OTP fields
                        HStack(spacing: 10) {
                            ForEach(0..<6, id: \.self) { index in
                                VStack {
                                    ZStack {
                                        // Display digit or empty space
                                        Text(otpDigits[index])
                                            .font(.LibreCaslon(size: 40))
                                            .foregroundStyle(isVerifying ? Color.gray : Color.black)
                                            .frame(width: 40, height: 50)
                                        
                                        // Show cursor on current field
                                        if index == otpText.count && isInputFocused && !isVerifying {
                                            Rectangle()
                                                .fill(Color.black)
                                                .frame(width: 2, height: 30)
                                                .animation(.easeInOut(duration: 0.5).repeatForever(), value: isInputFocused)
                                        }
                                    }
                                    
                                    // Bottom divider for each input field
                                    Divider()
                                        .frame(height: 2)
                                        .background(isVerifying ? Color.gray : Color.black.opacity(0.58))
                                }
                            }
                        }
                        .onTapGesture {
                            isInputFocused = true
                        }
                    }
                    .padding(.top, 50)
                    
                    // MARK: - Loading Indicator
                    if isVerifying {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .padding(.top, 20)
                    }
                    
                    // MARK: - Resend Code Button
                    HStack {
                        Spacer()
                        Button {
                            resendCode()
                        } label: {
                            Text("resend code")
                                .foregroundStyle(Color.blue)
                                .font(.LeagueSpartan(size: 15))
                        }
                        .disabled(isVerifying)
                    }
                    .padding(.top, 5)
                    
                    Spacer()
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
        }
        .navigationBarBackButtonHidden()  // Hide default back button to prevent accidental navigation
        // Focus on the input field when the view appears
        .onAppear {
            isInputFocused = true
        }
    }
    
    // MARK: - Input Handling Methods
    
    /// Handles OTP input with improved focus management and backspace behavior
    private func handleOTPInput(oldValue: String, newValue: String) {
        // Limit to 6 digits maximum
        if newValue.count > 6 {
            otpText = String(newValue.prefix(6))
            return
        }
        
        // Only allow numeric input
        let filtered = newValue.filter { $0.isNumber }
        if filtered != newValue {
            otpText = filtered
            return
        }
        
        // Auto-verify when all 6 digits are entered
        if newValue.count == 6 {
            verifyOTP()
        }
    }
    
    private func verifyOTP() {
        guard !isVerifying else { return }
        isVerifying = true
        isInputFocused = false // Dismiss keyboard
        
        let code = otpText
        OtpVerify.verifyOTP(code) { success in
            isVerifying = false
            if !success {
                showError = true
            }
        }
    }
    
    private func resendCode() {
        guard let phoneNumber = UserDefaults.standard.string(forKey: "UserPhoneNumber") else {
            appController.errorMessage = "No phone number found"
            showError = true
            return
        }
        
        let userPhone = UserPhoneNumber(number: phoneNumber, country: Country(id: "0235", name: "USA", flag: "🇺🇸", code: "US", dial_code: "+1", pattern: "### ### ####", limit: 17))
        userPhone.sendVerificationCode { success in
            if !success {
                appController.errorMessage = "Failed to resend verification code"
                showError = true
            }
        }
    }
}

// MARK: - Preview
#Preview {
    OtpVerifyView()
        .environmentObject(AppController.shared)
}
