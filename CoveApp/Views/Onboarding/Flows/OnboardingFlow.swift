//
//  OnboardingFlow.swift
//  Cove
//

import SwiftUI

struct OnboardingFlow: View {
    
    @EnvironmentObject var appController: AppController

    var body: some View {
        NavigationStack(path: $appController.path) {
            LoginView()
                .navigationDestination(for: OnboardingRoute.self) { route in
                    switch route {
<<<<<<< HEAD:Cove/Cove/Features/Onboarding/OnboardingFlow.swift
                    case .personality:
                        HobbiesPersonality(viewModel: viewModel)
                    case .profilePic:
                        PersonalizeProfile(viewModel: viewModel)
                    case .mutuals:
                        Mutuals(viewModel: viewModel)
=======
                    case .enterPhoneNumber:
                        UserPhoneNumberView()
                    case .otpVerify:
                        OtpVerifyView()
                    case .userDetails:
                        NamePageView()
                    case .birthdate:
                        BirthdateView()
>>>>>>> main:CoveApp/Views/Onboarding/Flows/OnboardingFlow.swift
                    case .finished:
                        EmptyView()
                    }
                }
        }
        .ignoresSafeArea(.keyboard)
    }
}

struct OnboardingBackgroundView: View {

    let imageName: String
    
    var body: some View {
        Image(imageName)
            .resizable()
            .scaledToFill()
//            .overlay(Color.white.opacity(0.4))
            .frame(minWidth: 0, maxWidth: .infinity)
            .ignoresSafeArea()
    }
}

