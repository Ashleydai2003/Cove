//
//  CoveApp.swift
//  Cove
//
//  Created by Ashley Dai on 4/14/25.
//

import SwiftUI
import UIKit

// MARK: - DEVELOPMENT FLAGS
#if DEBUG
/// Set this to true to skip onboarding flow entirely for development
private let SKIP_ONBOARDING_FOR_DEV = true
#endif

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

        // NOTE: Previously we force-reset the onboarding flag on every launch for
        // development. This caused fully-onboarded users to be treated as new
        // users and skip the data-loading flow. The line is now removed so the
        // persisted onboarding status returned from the backend is respected.
    }

    var body: some Scene {
        WindowGroup {
            // Use Group & transitions for smoother authentication switches
            Group {
                #if DEBUG
                if SKIP_ONBOARDING_FOR_DEV {
                    // DEV: Skip onboarding entirely
                    HomeView()
                        .environmentObject(appController)
                        .preferredColorScheme(.light)
                } else {
                    // Normal DEBUG logic
                    if appController.isLoggedIn {
                        // Main app flow - tab-based navigation
                        HomeView()
                            .environmentObject(appController)
                            .preferredColorScheme(.light)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    } else {
                        // Onboarding flow - linear navigation
                        OnboardingFlow()
                            .environmentObject(appController)
                            .preferredColorScheme(.light)
                            .transition(.asymmetric(
                                insertion: .move(edge: .leading).combined(with: .opacity),
                                removal: .move(edge: .trailing).combined(with: .opacity)
                            ))
                    }
                }
                #else
                // RELEASE logic
                if appController.isLoggedIn {
                    // Main app flow - tab-based navigation
                    HomeView()
                        .environmentObject(appController)
                        .preferredColorScheme(.light)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                } else {
                    // Onboarding flow - linear navigation
                    OnboardingFlow()
                        .environmentObject(appController)
                        .preferredColorScheme(.light)
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        ))
                }
                #endif
            }
            .animation(.easeInOut(duration: 0.45), value: appController.isLoggedIn)
        }
    }
}

