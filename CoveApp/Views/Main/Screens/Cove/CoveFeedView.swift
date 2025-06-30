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
                CoveBannerView()
                
                // Only show loading if we have no coves AND we're actively loading
                // (coves should already be fetched during onboarding)
                if coveFeed.userCoves.isEmpty && coveFeed.isLoading {
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
            // Only fetch if we don't have any coves (they should be fetched during onboarding)
            if coveFeed.userCoves.isEmpty {
                coveFeed.fetchUserCoves()
            }
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
