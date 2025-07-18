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
                    case .enterPhoneNumber:
                        UserPhoneNumberView()
                    case .otpVerify:
                        OtpVerifyView()
                    case .userDetails:
                        NamePageView()
                    case .birthdate:
                        BirthdateView()
                    case .almaMater:
                        AlmaMaterView()
                    case .citySelection:
                        CitySelectionView()
                    case .hobbies:
                        HobbiesView()
                    case .profilePics:
                        ProfilePicView()
                    case .pluggingIn:
                        PluggingYouIn()
                    }
                }
        }
        .ignoresSafeArea(.keyboard)
    }
}

