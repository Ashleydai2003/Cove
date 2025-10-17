//
//  VendorOnboardingFlow.swift
//  Cove
//
//  Vendor onboarding flow - updated to use NavigationStack like user onboarding

import SwiftUI
import FirebaseAuth

struct VendorOnboardingFlow: View {
    @StateObject private var vendorController = VendorController.shared
    
    var body: some View {
        NavigationStack(path: $vendorController.path) {
            VendorLoginStartView()
                .environmentObject(vendorController)
                .navigationDestination(for: VendorOnboardingStep.self) { step in
                    switch step {
                    case .phoneEntry:
                        VendorPhoneNumberView()
                            .environmentObject(vendorController)
                    case .otpVerify:
                        VendorOtpVerifyView()
                            .environmentObject(vendorController)
                    case .codeEntry:
                        VendorCodeEntryView()
                            .environmentObject(vendorController)
                    case .createOrganization:
                        CreateVendorOrganizationView()
                            .environmentObject(vendorController)
                    case .userDetails:
                        VendorUserDetailsView()
                            .environmentObject(vendorController)
                    case .complete:
                        VendorHomeView()
                            .environmentObject(vendorController)
                    case .initial:
                        VendorLoginStartView()
                            .environmentObject(vendorController)
                    }
                }
        }
        .ignoresSafeArea(.keyboard)
        .onAppear {
            AppController.isVendorFlowActive = true
        }
        .onDisappear {
            AppController.isVendorFlowActive = false
        }
    }
}

#Preview {
    VendorOnboardingFlow()
}