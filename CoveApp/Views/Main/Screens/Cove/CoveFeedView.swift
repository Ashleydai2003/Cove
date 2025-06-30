//
//  CoveFeedView.swift
//  Cove
//
//  Created by Ashley Dai on 6/29/25.
//

import SwiftUI

struct CoveFeedView: View {
    @EnvironmentObject var appController: AppController
    @ObservedObject private var coveFeed: CoveFeed
    
    init() {
        // Initialize with the shared instance
        self._coveFeed = ObservedObject(wrappedValue: AppController.shared.coveFeed)
    }
    
    // MARK: - Main Body 
    var body: some View {
        ZStack {
            Colors.faf8f4
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom Header
                HStack {
                    Spacer()
                    Text("cove")
                        .font(.LibreBodoniBold(size: 32))
                        .foregroundColor(Colors.primaryDark)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                    Spacer(minLength: 0)
                    HStack(spacing: 18) {
                        Button(action: { /* TODO: Inbox action */ }) {
                            Image(systemName: "envelope")
                                .resizable()
                                .frame(width: 28, height: 22)
                                .foregroundColor(Colors.primaryDark)
                        }
                        Button(action: { /* TODO: Paper plane action */ }) {
                            Image(systemName: "paperplane")
                                .resizable()
                                .frame(width: 26, height: 26)
                                .foregroundColor(Colors.primaryDark)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 8)
                
                if coveFeed.isLoading && coveFeed.userCoves.isEmpty {
                    VStack(spacing: 16) {
                        ProgressView()
                            .tint(Colors.primaryDark)
                        Text("loading your coves...")
                            .font(.LibreBodoni(size: 16))
                            .foregroundColor(Colors.primaryDark)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = coveFeed.errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.circle")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        
                        Text(error)
                            .font(.LibreBodoni(size: 16))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if coveFeed.userCoves.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "house")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        
                        Text("no coves found")
                            .font(.LibreBodoni(size: 16))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(Array(coveFeed.userCoves.enumerated()), id: \.element.id) { idx, cove in
                                CoveCardView(cove: cove)
                                if idx < coveFeed.userCoves.count - 1 {
                                    Divider()
                                        .padding(.leading, 84)
                                }
                            }
                        }
                        .padding(.horizontal, 0)
                        .padding(.top, 8)
                    }
                }
            }
        }
        .navigationBarBackButtonHidden()
        .onAppear {
            coveFeed.fetchUserCoves()
        }
        .onDisappear {
            coveFeed.cancelRequests()
        }
        .alert("error", isPresented: Binding(
            get: { coveFeed.errorMessage != nil },
            set: { if !$0 { coveFeed.errorMessage = nil } }
        )) {
            Button("ok") { coveFeed.errorMessage = nil }
        } message: {
            Text(coveFeed.errorMessage ?? "")
        }
    }
}

#Preview {
    CoveFeedView()
        .environmentObject(AppController.shared)
}
