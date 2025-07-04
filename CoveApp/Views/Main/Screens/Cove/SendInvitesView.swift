import SwiftUI

struct SendInvitesView: View {
    let coveId: String
    let coveName: String
    let sendAction: (() -> Void)?
    let onDataSubmit: (([String], String) -> Void)?
    
    @StateObject private var viewModel: SendInvitesModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Int?
    
    init(coveId: String, coveName: String, sendAction: (() -> Void)? = nil, onDataSubmit: (([String], String) -> Void)? = nil, initialPhoneNumbers: [String] = [], initialMessage: String = "") {
        self.coveId = coveId
        self.coveName = coveName
        self.sendAction = sendAction
        self.onDataSubmit = onDataSubmit
        self._viewModel = StateObject(wrappedValue: SendInvitesModel(coveId: coveId, initialPhoneNumbers: initialPhoneNumbers, initialMessage: initialMessage))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Colors.faf8f4.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            // Header with cove name
                            VStack(alignment: .leading, spacing: 8) {
                                Text("invite friends to")
                                    .font(.LibreBodoni(size: 16))
                                    .foregroundColor(Colors.k292929)
                                
                                Text(coveName)
                                    .font(.LibreBodoniBold(size: 24))
                                    .foregroundColor(Colors.primaryDark)
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 50)
                            
                            // Phone numbers section
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Text("phone numbers")
                                        .font(.LibreBodoniBold(size: 18))
                                        .foregroundColor(Colors.primaryDark)
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        viewModel.addPhoneNumber()
                                        // Focus on the new field
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                            focusedField = viewModel.phoneNumbers.count - 1
                                        }
                                    }) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(Colors.primaryDark)
                                    }
                                }
                                .padding(.horizontal, 24)
                                
                                // Phone number inputs
                                ForEach(Array(viewModel.phoneNumbers.enumerated()), id: \.offset) { index, phoneNumber in
                                    PhoneNumberInputView(
                                        phoneNumber: phoneNumber,
                                        countryCode: viewModel.countryCode,
                                        index: index,
                                        canRemove: viewModel.phoneNumbers.count > 1,
                                        onUpdatePhoneNumber: { newValue in
                                            viewModel.updatePhoneNumber(at: index, with: newValue)
                                        },
                                        onUpdateCountryCode: { newCode in
                                            viewModel.countryCode = newCode
                                        },
                                        onRemove: {
                                            viewModel.removePhoneNumber(at: index)
                                        }
                                    )
                                    .focused($focusedField, equals: index)
                                }
                            }
                            
                            // Message section
                            VStack(alignment: .leading, spacing: 12) {
                                Text("invitation message (optional)")
                                    .font(.LibreBodoniBold(size: 18))
                                    .foregroundColor(Colors.primaryDark)
                                    .padding(.horizontal, 24)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    TextEditor(text: $viewModel.message)
                                        .font(.LibreBodoni(size: 16))
                                        .foregroundColor(Colors.k292929)
                                        .padding(16)
                                        .frame(minHeight: 100)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.white)
                                                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                        )
                                    
                                    Text("add a personal touch to your invitation")
                                        .font(.LibreBodoni(size: 12))
                                        .foregroundColor(.gray)
                                }
                                .padding(.horizontal, 24)
                            }
                            
                            // Results section
                            if viewModel.showResults {
                                ResultsView(results: viewModel.inviteResults)
                                    .padding(.horizontal, 24)
                            }
                            
                            // Error/Success messages
                            if let errorMessage = viewModel.errorMessage {
                                Text(errorMessage)
                                    .font(.LibreBodoni(size: 14))
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 24)
                            }
                            
                            if let successMessage = viewModel.successMessage {
                                Text(successMessage)
                                    .font(.LibreBodoni(size: 14))
                                    .foregroundColor(.green)
                                    .padding(.horizontal, 24)
                            }
                            
                            Spacer(minLength: 100) // Space for bottom button
                        }
                    }
                    
                    // Send button at bottom
                    SendInviteButton(
                        isLoading: viewModel.isLoading,
                        isFormValid: viewModel.isFormValid,
                        action: {
                            // First, pass data back if callback is provided
                            if let onDataSubmit = onDataSubmit {
                                let phoneNumbers = viewModel.getValidPhoneNumbers()
                                onDataSubmit(phoneNumbers, viewModel.message)
                            }
                            
                            // Then execute the action
                            if let customAction = sendAction {
                                customAction()
                            } else {
                                viewModel.sendInvites()
                            }
                        }
                    )
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(Colors.primaryDark)
                    }
                }
            }
        }
        .onAppear {
            // Focus on first field when view appears
            focusedField = 0
        }
    }
}

/// Extracted send button component styled like create button
struct SendInviteButton: View {
    let isLoading: Bool
    let isFormValid: Bool
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.gray.opacity(0.3))
            
            Button(action: action) {
                if isLoading {
                    ProgressView()
                        .tint(.black)
                        .frame(maxWidth: .infinity, minHeight: 60, maxHeight: 60, alignment: .center)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.white)
                        )
                } else {
                    Text("send")
                        .foregroundStyle(!isFormValid ? Color.gray : Color.black)
                        .font(.LibreBodoniBold(size: 16))
                        .frame(maxWidth: .infinity, minHeight: 60, maxHeight: 60, alignment: .center)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(!isFormValid ? Color.gray.opacity(0.3) : Color.white)
                        )
                }
            }
            .disabled(!isFormValid || isLoading)
            .padding(.horizontal, 32)
            .padding(.vertical, 24)
            .background(Colors.faf8f4)
        }
    }
}

/// Individual phone number input field with country code
struct PhoneNumberInputView: View {
    let phoneNumber: String
    let countryCode: String
    let index: Int
    let canRemove: Bool
    let onUpdatePhoneNumber: (String) -> Void
    let onUpdateCountryCode: (String) -> Void
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Country code input
            TextField("+1", text: .init(
                get: { countryCode },
                set: onUpdateCountryCode
            ))
            .font(.LibreBodoni(size: 16))
            .foregroundColor(Colors.k292929)
            .keyboardType(.phonePad)
            .textContentType(.telephoneNumber)
            .frame(width: 60)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            
            // Phone number input
            TextField("phone number", text: .init(
                get: { phoneNumber },
                set: onUpdatePhoneNumber
            ))
            .font(.LibreBodoni(size: 16))
            .foregroundColor(Colors.k292929)
            .keyboardType(.phonePad)
            .textContentType(.telephoneNumber)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            
            if canRemove {
                Button(action: onRemove) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.red)
                }
            }
        }
        .padding(.horizontal, 24)
    }
}

/// Results display view
struct ResultsView: View {
    let results: [SendInvitesModel.InviteResult]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("results")
                .font(.LibreBodoniBold(size: 18))
                .foregroundColor(Colors.primaryDark)
            
            VStack(spacing: 8) {
                ForEach(Array(results.enumerated()), id: \.offset) { _, result in
                    HStack {
                        Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(result.success ? .green : .red)
                        
                        Text(result.phoneNumber)
                            .font(.LibreBodoni(size: 14))
                            .foregroundColor(Colors.k292929)
                        
                        if !result.success, let error = result.error {
                            Text("• \(error)")
                                .font(.LibreBodoni(size: 12))
                                .foregroundColor(.red)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(result.success ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                    )
                }
            }
        }
    }
}

#Preview {
    SendInvitesView(
        coveId: "preview-cove-id",
        coveName: "San Francisco Tech Meetup",
        sendAction: nil,
        onDataSubmit: nil,
        initialPhoneNumbers: [],
        initialMessage: ""
    )
} 