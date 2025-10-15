//
//  VendorLoginStartView.swift
//  Cove
//
//  Initial vendor portal landing page

import SwiftUI

struct VendorLoginStartView: View {
    @EnvironmentObject var vendorController: VendorController
    @Environment(\.dismiss) private var dismiss
    @AppStorage("activeAccountType") private var activeAccountType: String = "user"
    
    var body: some View {
        ZStack {
            OnboardingBackgroundView()
            
            VStack(spacing: 30) {
                Spacer()
                
                Text("vendor portal")
                    .font(.LibreBodoni(size: 48))
                    .foregroundColor(Colors.primaryDark)
                
                Text("create events for your business")
                    .font(.LeagueSpartan(size: 18))
                    .foregroundColor(Colors.primaryDark.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Spacer()
                
                Button {
                    vendorController.path.append(.phoneEntry)
                } label: {
                    Text("get started")
                        .font(.LeagueSpartan(size: 20))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Colors.primaryDark)
                        .cornerRadius(10)
                }
                .padding(.horizontal, 40)
                
                Button {
                    AppController.isVendorFlowActive = false
                    activeAccountType = "user"
                    dismiss()
                } label: {
                    Text("back to user login")
                        .font(.LeagueSpartan(size: 16))
                        .foregroundColor(Colors.primaryDark)
                        .underline()
                }
                .padding(.bottom, 40)
            }
        }
    }
}

#Preview {
    VendorLoginStartView()
        .environmentObject(VendorController.shared)
}

