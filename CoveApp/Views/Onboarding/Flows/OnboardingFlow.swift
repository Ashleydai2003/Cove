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
                    case .adminVerify:
                        AdminVerifyView()
                    case .userDetails:
                        NamePageView()
                    case .birthdate:
                        BirthdateView()
                    case .userLocation:
                        UserLocationView()
                    case .almaMater:
                        AlmaMaterView()
                    case .moreAboutYou:
                        MoreAboutYouView()
                    case .hobbies:
                        HobbiesView()
                    case .bio:
                        BioView()
                    case .profilePics:
                        ProfilePicView()
                    case .contacts:
                        ContactsView()
                    case .pluggingIn:
                        PluggingYouIn()
                    }
                }
        }
        .ignoresSafeArea(.keyboard)
    }
}

struct OnboardingBackgroundView: View {
    var body: some View {
        Color(hex: "F5F0E6").ignoresSafeArea()
    }
}

