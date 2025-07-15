//
//  PersonalizeProfile.swift
//  Cove
//
//  Created by Nesib Muhedin

import SwiftUI

struct ProfilePicView: View {
    @EnvironmentObject var appController: AppController

    // MARK: – Image state
    @State private var mainImage: UIImage?
    @State private var processingImage = false
    @State private var uploadMessage: String?
    @State private var isProcessing = false

    // MARK: - Loading View Component
    private struct LoadingImageView: View {
        let size: CGSize
        let message: String?
        
        var body: some View {
            ZStack {
                    Circle()
                        .fill(Colors.f3f3f3)
                        .frame(width: size.width, height: size.height)
                        .overlay(Circle().stroke(Color.black, lineWidth: 0.5))
                
                if let message = message {
                    Text(message)
                        .font(.LeagueSpartan(size: 12))
                        .foregroundStyle(.black)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                } else {
                    ProgressView()
                }
            }
        }
    }

    // Image picker sheet state
    @State private var showingImagePicker = false
    @State private var isCompletingOnboarding = false
    @State private var showingError = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Colors.faf8f4.ignoresSafeArea()

                VStack(spacing: 20) {
                    // Back + Title block (leading)
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Button { appController.path.removeLast() } label: {
                                Images.backArrow
                            }
                            Spacer()
                        }
                        .padding(.top, 10)

                        Text("personalize your")
                            .foregroundStyle(Colors.primaryDark)
                            .font(.LibreBodoni(size: 34))
                        Text("profile")
                            .foregroundStyle(Colors.primaryDark)
                            .font(.LibreBodoni(size: 34))

                        Text("add a profile picture to show off your vibe")
                            .foregroundStyle(.black)
                            .font(.LeagueSpartan(size: 12))
                    }
                    .padding(.horizontal, 20)

                    Spacer()

                    // Main profile picture selector
                    VStack(spacing: 20) {
                        Button {
                            showingImagePicker = true
                        } label: {
                            if processingImage {
                                LoadingImageView(size: CGSize(width: 160, height: 160), message: nil)
                            } else if let message = uploadMessage {
                                LoadingImageView(size: CGSize(width: 160, height: 160), message: message)
                            } else if let img = mainImage {
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 160, height: 160)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.black, lineWidth: 0.5))
                            } else {
                                ZStack {
                                    Circle()
                                        .fill(Colors.f3f3f3)
                                        .frame(width: 160, height: 160)
                                        .overlay(Circle().stroke(Color.black, lineWidth: 0.5))
                                    Text("+")
                                        .font(.system(size: 30))
                                        .foregroundColor(.black)
                                }
                            }
                        }

                        Text("tap to select profile picture")
                            .font(.LeagueSpartan(size: 14))
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)

                    Spacer()

                    // Continue button
                    HStack {
                        Spacer()
                        if isCompletingOnboarding {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(1.2)
                                .frame(width: 52, height: 52)
                                .padding(.trailing, 20)
                        } else {
                            Images.nextArrow
                                .resizable()
                                .frame(width: 52, height: 52)
                                .padding(.trailing, 20)
                                .onTapGesture {
                                    completeOnboarding()
                                }
                        }
                    }
                }
                .safeAreaPadding()
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $mainImage)
            }
            .onChange(of: mainImage) { old, new in
                if let img = new {
                    processingImage = true
                    uploadMessage = nil
                    // Simulate a small delay to show loading state
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        processingImage = false
                        Onboarding.storeProfilePic(img)
                    }
                }
            }
            .alert("Onboarding Failed", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(appController.errorMessage.isEmpty ? "Failed to complete onboarding. Please try again." : appController.errorMessage)
            }
        }
        .navigationBarBackButtonHidden()
    }
    
    // MARK: - Onboarding Completion
    
    private func completeOnboarding() {
        // Prevent multiple completion attempts
        guard !isCompletingOnboarding else { return }
        
        isCompletingOnboarding = true
        
        // Store the profile picture if one was selected
        if let mainImage = mainImage {
            Onboarding.storeProfilePic(mainImage)
        }
        
        // Complete the onboarding process
        Onboarding.completeOnboarding { success in
            DispatchQueue.main.async {
                isCompletingOnboarding = false
                
                if success {
                    // Navigate to data loading screen
                    appController.path = [.pluggingIn]
                } else {
                    // Show error message - the AppController.errorMessage will be set by Onboarding.completeOnboarding
                    Log.error("Failed to complete onboarding from ProfilePicView")
                    showingError = true
                }
            }
        }
    }
}

// Preview
#Preview {
    ProfilePicView()
        .environmentObject(AppController.shared)
}
