//
//  OtpVerifyView.swift
//  Cove
//
//  Created by Ananya Agarwal

// TODO: allow backspace when field is empty

import SwiftUI

/// View for handling OTP (One-Time Password) verification during user onboarding
/// Manages a 6-digit verification code input with automatic field advancement
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
    
    /// Inline error message below OTP digits
    @State private var otpErrorMessage: String = ""
    
    /// Status messaging
    @State private var statusMessage: String = ""
    @State private var messageType: MessageType = .none
    
    /// Rate limiting for resend
    @State private var lastResendTime: Date = Date.distantPast
    @State private var resendCooldownRemaining: Int = 0
    @State private var cooldownTimer: Timer?
    
    enum MessageType {
        case none
        case success
        case error
    }
    
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
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .animation(.easeInOut(duration: 0.3), value: statusMessage)
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
                            // Clear verification state but keep phone number
                            OtpVerify.clearVerificationState()
                            
                            // Reset local state
                            statusMessage = ""
                            messageType = .none
                            otpErrorMessage = ""
                            otpText = ""
                            
                            // Navigate back (UserPhoneNumberView will auto-send again)
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
                    
                    // MARK: - OTP Error Message (inline below digits)
                    if !otpErrorMessage.isEmpty {
                        HStack {
                            Text(otpErrorMessage)
                                .font(.LeagueSpartan(size: 12))
                                .foregroundColor(.red)
                                .padding(.top, 8)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .animation(.easeInOut(duration: 0.3), value: otpErrorMessage)
                    }
                    
                    // MARK: - Status Message
                    statusMessageView
                    
                    // MARK: - Loading Indicator
                    if isVerifying {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .padding(.top, 20)
                    }
                    
                    // MARK: - Resend Code Button
                    HStack {
                        Spacer()
                        resendButton
                    }
                    .padding(.top, 5)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .safeAreaPadding()
                // Error alert (fallback)
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
        .onDisappear {
            // Clean up timer when view disappears
            cooldownTimer?.invalidate()
            cooldownTimer = nil
        }
    }
    
    // MARK: - Resend Button
    
    private var resendButton: some View {
        Button {
            resendCodeWithCooldown()
        } label: {
            if resendCooldownRemaining > 0 {
                Text("resend code (\(resendCooldownRemaining)s)")
                    .foregroundColor(.gray)
                    .font(.LeagueSpartan(size: 15))
            } else {
                Text("resend code")
                    .foregroundColor(.blue)
                    .font(.LeagueSpartan(size: 15))
            }
        }
        .disabled(resendCooldownRemaining > 0 || isVerifying)
    }
    
    // MARK: - Input Handling Methods
    
    /// Handles OTP input with improved focus management and backspace behavior
    private func handleOTPInput(oldValue: String, newValue: String) {
        // Clear error message when user starts typing (especially on backspace)
        if newValue.count < oldValue.count && !otpErrorMessage.isEmpty {
            otpErrorMessage = ""
        }
        
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
        otpErrorMessage = "" // Clear previous error
        statusMessage = "Verifying..."
        messageType = .none
        
        let code = otpText
        OtpVerify.verifyOTP(code) { success in
            isVerifying = false
            
            if success {
                // Success - dismiss keyboard since we're navigating away
                isInputFocused = false
                statusMessage = ""
                messageType = .none
                otpErrorMessage = ""
            } else {
                // Show inline error below OTP digits - keep keyboard active for immediate editing
                otpErrorMessage = "Incorrect code. Please check and try again."
                statusMessage = ""
                messageType = .none
                // Reset focus to last digit for immediate backspace
                isInputFocused = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isInputFocused = true
                }
            }
        }
    }
    
    private func resendCodeWithCooldown() {
        guard resendCooldownRemaining == 0 else { return }
        
        // Start cooldown
        lastResendTime = Date()
        resendCooldownRemaining = 5
        startCooldownTimer()
        
        // Clear previous messages
        otpErrorMessage = ""
        statusMessage = "Sending code..."
        messageType = .none
        
        resendCode { result in
            switch result {
            case .success:
                statusMessage = "Code sent!"
                messageType = .success
                otpText = "" // Clear OTP input
                isInputFocused = true // Focus on first digit
                
            case .invalidPhoneNumber:
                statusMessage = "Failure to send code, check that your phone number is correct."
                messageType = .error
                
            case .networkError:
                statusMessage = "Network error. Please check your connection and try again."
                messageType = .error
                
            case .rateLimited:
                statusMessage = "Wait just a few seconds and try to resend again."
                messageType = .error
                
            case .unknownError(let message):
                statusMessage = "Code failed to send—try another phone number."
                messageType = .error
            }
        }
    }
    
    private func startCooldownTimer() {
        cooldownTimer?.invalidate()
        cooldownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if resendCooldownRemaining > 0 {
                resendCooldownRemaining -= 1
            } else {
                cooldownTimer?.invalidate()
                cooldownTimer = nil
            }
        }
    }
    
    private func resendCode(completion: @escaping (CodeSendResult) -> Void) {
        guard let phoneNumber = UserDefaults.standard.string(forKey: "UserPhoneNumber") else {
            completion(.unknownError("No phone number found"))
            return
        }
        
        let userPhone = UserPhoneNumber(number: phoneNumber, country: Country(id: "0235", name: "USA", flag: "🇺🇸", code: "US", dial_code: "+1", pattern: "### ### ####", limit: 17))
        userPhone.sendVerificationCode { result in
            completion(result)
        }
    }
}

// MARK: - Preview
#Preview {
    OtpVerifyView()
        .environmentObject(AppController.shared)
}
