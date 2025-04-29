//
//  OnboardingViewModel.swift
//  Cove
//
//  Created by Sheng Moua on 4/21/25.
//

import SwiftUI

enum OnboardingRoute: Hashable {
    case enterPhoneNumber
    case optVerify
    case userDetails
    case birthdate
    case finished
}

final class OnboardingViewModel: ObservableObject {
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding = false
    @Published var path: [OnboardingRoute] = []

    func completeOnboarding() {
        hasCompletedOnboarding = true
    }
}
