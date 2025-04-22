//
//  CoveApp.swift
//  Cove
//
//  Created by Ashley Dai on 4/14/25.
//

import SwiftUI

@main
struct MyApp: App {
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding = false
    
    init() {
            // For development: always reset onboarding status
            UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
        
            for family in UIFont.familyNames {
                print("Font family: \(family)")
                for name in UIFont.fontNames(forFamilyName: family) {
                    print("   \(name)")
                }
        }

        }

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                LandingView()
            } else {
                OnboardingFlow()
            }
        }
    }
}

