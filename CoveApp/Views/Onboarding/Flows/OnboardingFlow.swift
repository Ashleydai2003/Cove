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
                    case .mutuals:
                        MutualsView()
                    case .pluggingIn:
                        PluggingYouIn()
                    case .profile:
                        ProfileView()
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

