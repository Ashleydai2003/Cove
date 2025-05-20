//
//  MutualsView.swift
//  Cove
//
//  Created by Sheng Moua on 4/22/25.
//

import SwiftUI

struct MutualsView: View {
    @EnvironmentObject var appController: AppController
    @State private var bio: String = ""
    @State private var showError = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Colors.faf8f4
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Button {
                            appController.path.removeLast()
                        } label: {
                            Images.backArrow
                        }
                        Spacer()
                    }
                    .padding(.top, 10)

                    // Title and description
                    VStack(alignment: .leading, spacing: 10) {
                        Text("add friends")
                            .foregroundStyle(Colors.primaryDark)
                            .font(.LibreBodoni(size: 35))
                        
                        Text("cove is a secure, curated network. let us help you find your friends of friends.")
                            .foregroundStyle(.black)
                            .font(.LeagueSpartan(size: 12))
                        
                        Text("we never share phone numbers.")
                            .foregroundStyle(.black)
                            .font(.LeagueSpartan(size: 12))
                        
                        Text("add at least 5 friends. the more genuine friends you add, the better cove will work for you. we ONLY see the contacts you choose.")
                            .foregroundStyle(.black)
                            .font(.LeagueSpartan(size: 12))
                    }
                    .padding(.top, 40)

                    Spacer()

                    // Contacts button
                    Button(action: {
                        // TODO: actually do contact syncing 
                        Onboarding.completeOnboarding { success in
                            if !success {
                                showError = true
                            }
                        }
                    }) {
                        Text("choose friends from contacts")
                            .font(.LibreBodoni(size: 16))
                            .foregroundStyle(.black)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.white)
                            .cornerRadius(15)
                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 4)
                    }
                    .padding(.bottom, 40)
                }
                .padding(.horizontal, 20)
                .safeAreaPadding()
            }
        }
        .navigationBarBackButtonHidden()
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(appController.errorMessage)
        }
    }
}

#Preview {
    MutualsView()
        .environmentObject(AppController.shared)
}

