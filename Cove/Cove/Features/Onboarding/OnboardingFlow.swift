//
//  OnboardingFlow.swift
//  Cove
//
//  Created by Sheng Moua on 4/21/25.
//

import SwiftUI

struct OnboardingFlow: View {
    @StateObject private var viewModel = OnboardingViewModel()

    var body: some View {
        NavigationStack(path: $viewModel.path) {
            WelcomeScreen(viewModel: viewModel)
                .navigationDestination(for: OnboardingRoute.self) { route in
                    switch route {
                    case .personality:
                        HobbiesPersonality(viewModel: viewModel)
                    case .profilePic:
                        PersonalizeProfile(viewModel: viewModel)
                    case .mutuals:
                        Mutuals(viewModel: viewModel)
                    case .finished:
                        EmptyView()
                    }
                }
        }
    }
}

