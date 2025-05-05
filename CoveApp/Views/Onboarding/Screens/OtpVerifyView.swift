//
//  OtpVerifyView.swift
//  Cove
//

import SwiftUI

struct OtpVerifyView: View {
    
    // Environment object to access shared app controller
    @EnvironmentObject var appController: AppController
    
    // State variables for managing OTP verification
    @State private var otp: [String] = Array(repeating: "", count: 5) // Array to store individual OTP digits
    @FocusState private var focusedIndex: Int? // Tracks which OTP digit field is focused
    @State private var isVerifying = false // Indicates verification process status
    @State private var showError = false // Controls error alert visibility
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background image with reduced opacity
                OnboardingBackgroundView(imageName: "otp_background")
                    .opacity(0.4)
                
                VStack {
                    // Back button to return to phone number entry
                    HStack {
                        Button {
                            appController.path.removeLast()
                        } label: {
                            Images.backArrow
                        }
                        Spacer()
                    }
                    .padding(.top, 10)
                    
                    // Title and phone number display section
                    VStack(alignment: .leading) {
                        Text("enter your \nverification code")
                            .foregroundStyle(Colors.primaryDark)
                            .font(.LibreBodoni(size: 40))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Display phone number with edit option
                        HStack(spacing: 0) {
                            Text("sent to \(appController.getFullPhoneNumber()) | ")
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
                    
                    // OTP input fields
                    HStack(spacing: 10) {
                        ForEach(0..<otp.count, id: \.self) { index in
                            VStack {
                                TextField("", text: $otp[index])
                                    .keyboardType(.numberPad)
                                    .foregroundStyle(Color.black)
                                    .multilineTextAlignment(.center)
                                    .font(.LibreCaslon(size: 40))
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .submitLabel(.done)
                                    .focused($focusedIndex, equals: index)
                                    .onChange(of: otp[index]) { oldValue, newValue in
                                        // Handle OTP input changes
                                        if newValue.count > 1 {
                                            otp[index] = String(newValue.prefix(1))
                                        }
                                        if !newValue.isEmpty && index < 5 {
                                            focusedIndex = index + 1
                                        } else if newValue.isEmpty && index > 0 {
                                            focusedIndex = index - 1
                                        }
                                        
                                        // Auto-verify when all digits are entered
                                        let enteredAllCode = otp.allSatisfy { !$0.isEmpty }
                                        if enteredAllCode {
                                            verifyOTP()
                                        }
                                    }
                                
                                Divider()
                                    .frame(height: 2)
                                    .background(Color.black.opacity(0.58))
                            }
                        }
                    }
                    .padding(.top, 50)
                    
                    // Resend code button
                    HStack {
                        Spacer()
                        Button {
                            resendCode()
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
                // Error alert
                .alert("Error", isPresented: $showError) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text(appController.errorMessage)
                }
            }
        }
        .navigationBarBackButtonHidden()
        // Send verification code when view appears
        .onAppear {
            sendVerificationCode()
        }
    }
    
    // Sends a new verification code to the phone number
    private func sendVerificationCode() {
        isVerifying = true
        appController.sendVerificationCode { success in
            isVerifying = false
            if !success {
                showError = true
            }
        }
    }
    
    // Verifies the entered OTP code
    private func verifyOTP() {
        let code = otp.joined()
        isVerifying = true
        
        appController.verifyOTP(code) { success in
            isVerifying = false
            if success {
                appController.path.append(.userDetails)
            } else {
                showError = true
            }
        }
    }
    
    // Resends the verification code
    private func resendCode() {
        sendVerificationCode()
    }
}

#Preview {
    OtpVerifyView()
        .environmentObject(AppController.shared)
}
