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
    @State private var navigationPath = NavigationPath()

    init() {
        // Initialize with the shared instance
        self._coveFeed = ObservedObject(wrappedValue: AppController.shared.coveFeed)
    }

    // MARK: - Main Body
    var body: some View {
        NavigationStack(path: $navigationPath) {
        ZStack {
            Colors.background
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
                            .foregroundColor(Colors.primaryDark)

                        Text("no coves found")
                            .font(.LibreBodoni(size: 16))
                            .foregroundColor(Colors.primaryDark)
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
                                        .padding(.leading, 100)
                                        .padding(.trailing, 20)
                                }
                            }
                        }
                        .padding(.horizontal, 0)
                        .padding(.top, 8)
                    }
                    .refreshable {
                        await withCheckedContinuation { continuation in
                            coveFeed.refreshUserCoves {
                                continuation.resume()
                            }
                        }
                    }
                    }
                }
            }
            .navigationDestination(for: String.self) { value in
                // This handles both cove IDs and event IDs
                // We can distinguish them by checking if it's a valid cove
                if let _ = appController.coveFeed.getCove(by: value) {
                    // It's a cove ID
                    CoveView(
                        viewModel: appController.coveFeed.getOrCreateCoveModel(for: value),
                        coveId: value
                    )
                } else {
                    // It's an event ID - try to find the event in cove data to get cover photo
                    let coverPhoto = findEventCoverPhoto(eventId: value)
                    EventPostView(eventId: value, coveCoverPhoto: coverPhoto)
                }
            }
        }
        .navigationBarBackButtonHidden()
        .onAppear {
            // Only fetch if we don't have any coves or data is stale
            coveFeed.fetchUserCovesIfStale()
        }
        .onChange(of: coveFeed.deepLinkToCoveId) { _, newValue in
            guard let coveId = newValue else { return }
            DispatchQueue.main.async {
                navigationPath.append(coveId)
                coveFeed.deepLinkToCoveId = nil
            }
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

    // Helper function to find event cover photo from cached cove data
    private func findEventCoverPhoto(eventId: String) -> CoverPhoto? {
        // Search through all cached cove models to find the event
        for coveModel in coveFeed.coveModels.values {
            if let event = coveModel.events.first(where: { $0.id == eventId }) {
                return event.coveCoverPhoto
            }
        }
        return nil
    }
}

#Preview {
    CoveFeedView()
        .environmentObject(AppController.shared)
}
