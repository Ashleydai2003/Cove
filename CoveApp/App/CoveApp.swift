//
//  CoveApp.swift
//  Cove
//
//  Created by Ashley Dai on 4/14/25.
//

import SwiftUI

@main
struct CoveApp: App {
    // firebase delegate
    @UIApplicationDelegateAdaptor(FirebaseSetup.self) var firebase_delegate
    
    /// Shared app controller instance
    @StateObject private var appController = AppController.shared
    
    init() {
            // For Injection (hot reloading)
            // Note flags -Xlinker -interposable under Other Linker Flags are for Injection
            #if DEBUG
            Bundle(path: "/Applications/InjectionIII.app/Contents/Resources/iOSInjection.bundle")?.load()
            #endif
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
            TmpView()
                .environmentObject(appController)
        }
    }
}

