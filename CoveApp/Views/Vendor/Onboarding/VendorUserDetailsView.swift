//
//  VendorUserDetailsView.swift
//  Cove
//
//  View for entering vendor user personal information
//

import SwiftUI
import PhotosUI

struct VendorUserDetailsView: View {
    @EnvironmentObject var vendorController: VendorController
    @State private var name: String = ""
    @State private var isSubmitting: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @FocusState private var isNameFocused: Bool
    
    // Photo upload states
    @State private var profilePhoto: UIImage?
    @State private var selectedItem: PhotosPickerItem?
    
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
                    Text("what's your \nname?")
                        .font(.LibreBodoni(size: 40))
                        .foregroundColor(Colors.primaryDark)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text("this is how you'll appear to your team")
                        .font(.LeagueSpartan(size: 15))
                        .foregroundColor(Colors.primaryDark)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.top, 40)
                
                // Name input
                VStack(spacing: 8) {
                    TextField("your name", text: $name)
                        .font(.LibreCaslon(size: 25))
                        .foregroundColor(Colors.primaryDark)
                        .autocorrectionDisabled()
                        .focused($isNameFocused)
                        .padding(.horizontal, 10)
                    
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
                
                // Profile Photo Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("profile photo (optional)")
                        .font(.LeagueSpartan(size: 14))
                        .foregroundColor(.gray)
                        .padding(.top, 20)
                    
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        ZStack {
                            if let profilePhoto = profilePhoto {
                                Image(uiImage: profilePhoto)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(Color.black.opacity(0.12), lineWidth: 2)
                                    )
                            } else {
                                Circle()
                                    .fill(Color.white.opacity(0.6))
                                    .overlay(
                                        Circle()
                                            .stroke(Color.black.opacity(0.12), lineWidth: 2)
                                    )
                                    .overlay(
                                        VStack(spacing: 8) {
                                            Image(systemName: "person.circle")
                                                .font(.system(size: 32))
                                                .foregroundColor(Colors.primaryDark.opacity(0.7))
                                            Text("add photo")
                                                .font(.LeagueSpartan(size: 12))
                                                .foregroundColor(Colors.primaryDark.opacity(0.7))
                                        }
                                    )
                                    .frame(width: 120, height: 120)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // Show vendor code if just created
                if let newCode = vendorController.newVendorCode {
                    VStack(spacing: 12) {
                        Text("Your Organization Code")
                            .font(.LeagueSpartan(size: 16))
                            .foregroundColor(Colors.primaryDark)
                        
                        Text(newCode)
                            .font(.system(size: 28, weight: .bold, design: .monospaced))
                            .foregroundColor(Colors.primaryDark)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Colors.primaryDark.opacity(0.1))
                            )
                        
                        Text("Share this code with your team members to join")
                            .font(.LeagueSpartan(size: 13))
                            .foregroundColor(Colors.primaryDark.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 32)
                }
                
                Spacer()
                
                // Complete setup button
                SignOnButton(text: isSubmitting ? "completing..." : "complete setup") {
                    completeOnboarding()
                }
                .disabled(!isValidName || isSubmitting)
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 20)
            .safeAreaPadding()
        }
        .navigationBarBackButtonHidden()
        .onAppear {
            isNameFocused = true
        }
        .onChange(of: selectedItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    profilePhoto = image
                }
            }
        }
    }
    
    private var isValidName: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func completeOnboarding() {
        guard isValidName else { return }
        
        isSubmitting = true
        showError = false
        
        VendorNetworkManager.shared.completeVendorOnboarding(name: name.trimmingCharacters(in: .whitespacesAndNewlines), profilePhoto: profilePhoto) { result in
            DispatchQueue.main.async {
                isSubmitting = false
                
                switch result {
                case .success:
                    // Mark onboarding as complete and move to main app
                    vendorController.hasCompletedOnboarding = true
                    vendorController.isLoggedIn = true
                    vendorController.path.append(.complete)
                case .failure(let error):
                    showError = true
                    errorMessage = "Error completing onboarding: \(error.localizedDescription)"
                }
            }
        }
    }
}

#Preview {
    VendorUserDetailsView()
        .environmentObject(VendorController.shared)
}
