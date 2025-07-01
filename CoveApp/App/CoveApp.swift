//
//  CoveApp.swift
//  Cove
//
//  Created by Ashley Dai on 4/14/25.
//

import SwiftUI
import UIKit

// TODO: fix dark mode
@main
struct CoveApp: App {
    // firebase delegate
    @UIApplicationDelegateAdaptor(FirebaseSetup.self) var firebase_delegate
    
    /// Shared app controller instance - now properly managed by SwiftUI
    @StateObject private var appController = AppController.shared
    
    init() {
        // For Injection (hot reloading)
        // Note flags -Xlinker -interposable under Other Linker Flags are for Injection
        #if DEBUG
        Bundle(path: "/Applications/InjectionIII.app/Contents/Resources/iOSInjection.bundle")?.load()
        #endif
        
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor(named: "CovePrimaryDarkColor")
        
        // Selected item color
        UITabBar.appearance().tintColor = UIColor.systemBlue
        // Unselected item color
        UITabBar.appearance().unselectedItemTintColor = UIColor.gray
        UITabBar.appearance().standardAppearance = tabBarAppearance
        // For scroll edge behavior
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }
        
        // For development: always reset onboarding status
        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
        
        // Print available fonts for debugging
        for family in UIFont.familyNames {
            print("Font family: \(family)")
            for name in UIFont.fontNames(forFamilyName: family) {
                print("   \(name)")
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            if appController.isLoggedIn {
                // Main app flow - tab-based navigation
                HomeView()
                    .environmentObject(appController)
            } else {
                // Onboarding flow - linear navigation
                OnboardingFlow()
                    .environmentObject(appController)
            }
        }
    }
}

