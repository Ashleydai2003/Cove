//
//  OnboardingFlow.swift
//  Cove
//

import SwiftUI

struct OnboardingFlow: View {
    
    @StateObject private var viewModel = OnboardingViewModel()

    var body: some View {
        NavigationStack(path: $viewModel.path) {
            LoginView()
                .navigationDestination(for: OnboardingRoute.self) { route in
                    switch route {
                    case .enterPhoneNumber:
                        UserPhoneNumberView()
                    case .optVerify:
                        OtpVerifyView()
                    case .userDetails:
                        NamePageView()
                    case .birthdate:
                        BirthdateView()
                    case .finished:
                        EmptyView()
                    }
                }
        }
        .environmentObject(viewModel)
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
