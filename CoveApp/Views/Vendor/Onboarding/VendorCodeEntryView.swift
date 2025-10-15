//
//  VendorCodeEntryView.swift
//  Cove
//
//  Vendor code entry for joining existing organization or creating new one
//

import SwiftUI

struct VendorCodeEntryView: View {
    @EnvironmentObject var vendorController: VendorController
    @State private var vendorCode: String = ""
    @State private var isValidating: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        ZStack {
            OnboardingBackgroundView()
            
            VStack {
                // Back button
                HStack {
                    Button {
                        vendorController.path.removeLast()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Colors.primaryDark)
                    }
                    Spacer()
                }
                .padding(.top, 10)
                
                // Header
                VStack(alignment: .leading) {
                    Text("join your \norganization")
                        .font(.LibreBodoni(size: 40))
                        .foregroundColor(Colors.primaryDark)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text("enter your vendor code to join an existing organization")
                        .font(.LeagueSpartan(size: 15))
                        .foregroundColor(Colors.primaryDark)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.top, 40)
                
                // Code input
                VStack(spacing: 12) {
                    TextField("XXXX-XXXX", text: $vendorCode)
                        .font(.LibreCaslon(size: 25))
                        .foregroundColor(Colors.primaryDark)
                        .multilineTextAlignment(.center)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .focused($isInputFocused)
                        .padding(.horizontal, 10)
                        .onChange(of: vendorCode) { _, newValue in
                            // Format code as XXXX-XXXX
                            let filtered = newValue.uppercased().filter { $0.isLetter || $0.isNumber || $0 == "-" }
                            var formatted = ""
                            for (index, char) in filtered.enumerated() {
                                if index == 4 && char != "-" {
                                    formatted += "-"
                                }
                                if formatted.count < 9 {
                                    formatted.append(char)
                                }
                            }
                            vendorCode = formatted
                        }
                    
                    Divider()
                        .frame(height: 2)
                        .background(Color.black.opacity(0.58))
                    
                    if showError {
                        Text(errorMessage)
                            .font(.LeagueSpartan(size: 12))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.top, 40)
                
                Spacer()
                
                // Buttons
                VStack(spacing: 16) {
                    // Join button
                    SignOnButton(text: isValidating ? "validating..." : "join organization") {
                        joinOrganization()
                    }
                    .disabled(vendorCode.count < 9 || isValidating)
                    
                    // Create new organization button
                    Button(action: {
                        vendorController.path.append(.createOrganization)
                    }) {
                        Text("create new organization")
                            .font(.LeagueSpartan(size: 16))
                            .foregroundColor(Colors.primaryDark)
                            .underline()
                    }
                    .disabled(isValidating)
                }
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 20)
            .safeAreaPadding()
        }
        .navigationBarBackButtonHidden()
        .onAppear {
            isInputFocused = true
        }
    }
    
    private func joinOrganization() {
        guard !vendorCode.isEmpty else { return }
        
        isValidating = true
        showError = false
        errorMessage = ""
        
        VendorNetworkManager.shared.validateVendorCode(code: vendorCode) { result in
            isValidating = false
            
            switch result {
            case .success:
                // Code is valid, now join the organization
                VendorNetworkManager.shared.joinVendorOrganization(code: vendorCode) { joinResult in
                    switch joinResult {
                    case .success:
                        vendorController.path.append(.userDetails)
                        
                    case .failure(let error):
                        showError = true
                        errorMessage = "Failed to join organization: \(error.localizedDescription)"
                    }
                }
                
            case .failure(let error):
                showError = true
                errorMessage = "Invalid code. Please check and try again."
                Log.error("Code validation error: \(error.localizedDescription)")
            }
        }
    }
}

#Preview {
    VendorCodeEntryView()
        .environmentObject(VendorController.shared)
}
