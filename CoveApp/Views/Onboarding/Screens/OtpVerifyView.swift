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
    
    /// Array to store individual digits of the OTP
    /// Initialized with 6 empty strings for each digit position
    @State private var otp: [String] = Array(repeating: "", count: 6)
    
    /// Tracks which OTP input field is currently focused
    /// Used for automatic field advancement and keyboard management
    @FocusState private var focusedIndex: Int?
    
    /// Tracks whether the OTP verification process is in progress
    @State private var isVerifying = false
    
    /// Tracks whether an error should be shown
    @State private var showError = false
    
    // Custom input accessory view for keyboard
    private var keyboardAccessoryView: some View {
        HStack {
            Spacer()
            Button("Done") {
                focusedIndex = nil
            }
            .padding(.trailing, 16)
            .padding(.vertical, 8)
        }
        .background(Color(.systemGray6))
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
                Colors.primaryLight.ignoresSafeArea()
                
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
                    HStack(spacing: 10) {
                        ForEach(0..<otp.count, id: \.self) { index in
                            VStack {
                                TextField("", text: $otp[index])
                                    .keyboardType(.numberPad)
                                    .foregroundStyle(isVerifying ? Colors.k6F6F73 : Color.black)
                                    .multilineTextAlignment(.center)
                                    .font(.LibreCaslon(size: 40))
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .submitLabel(.done)
                                    .focused($focusedIndex, equals: index)
                                    .textContentType(.oneTimeCode)
                                    .disabled(isVerifying)
                                    .toolbar {
                                        ToolbarItem(placement: .keyboard) {
                                            keyboardAccessoryView
                                        }
                                    }
                                    .onChange(of: otp[index]) { oldValue, newValue in
                                        handleOTPInput(at: index, oldValue: oldValue, newValue: newValue)
                                    }
                                
                                // Bottom divider for each input field
                                Divider()
                                    .frame(height: 2)
                                    .background(isVerifying ? Colors.k6F6F73 : Color.black.opacity(0.58))
                            }
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
                                .foregroundStyle(Colors.primaryDark)
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
        // Focus on the first input field when the view appears
        .onAppear {
            focusedIndex = 0
        }
    }
    
    // MARK: - Input Handling Methods
    
    /// Handles OTP input with improved focus management and backspace behavior
    private func handleOTPInput(at index: Int, oldValue: String, newValue: String) {
        // Handle multiple characters (paste scenario)
        if newValue.count > 1 {
            otp[index] = String(newValue.prefix(1))
        }
        
        // Handle backspace on empty field - delete previous digit
        if oldValue.isEmpty && newValue.isEmpty {
            // This is backspace on empty field, delete the last filled digit
            deleteLastDigit()
            return
        }
        
        // Handle normal input
        if newValue.isEmpty {
            // User deleted current digit, move focus to this field
            focusedIndex = index
        } else {
            // User entered a digit, move to next empty field
            DispatchQueue.main.async {
                self.updateFocusToNextEmptyField()
            }
        }
        
        // Auto-verify when all fields are filled
        if otp.allSatisfy({ !$0.isEmpty }) {
            verifyOTP()
        }
    }
    
    /// Deletes the last (rightmost) filled digit and updates focus
    private func deleteLastDigit() {
        // Find the last filled digit
        for i in stride(from: otp.count - 1, through: 0, by: -1) {
            if !otp[i].isEmpty {
                otp[i] = ""
                focusedIndex = i
                return
            }
        }
    }
    
    /// Updates focus to the first empty field, or removes focus if all are filled
    private func updateFocusToNextEmptyField() {
        // Find first empty field
        if let firstEmpty = otp.firstIndex(where: { $0.isEmpty }) {
            focusedIndex = firstEmpty
        } else {
            // All fields are filled, remove focus
            focusedIndex = nil
        }
    }
    
    private func verifyOTP() {
        guard !isVerifying else { return }
        isVerifying = true
        focusedIndex = nil // Dismiss keyboard
        
        let code = otp.joined()
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
