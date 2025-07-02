//
//  CoveView.swift (formerly FeedView.swift)
//  Cove
//
//  Created by Ananya Agarwal
//  Refactored and documented by AI for maintainability and best practices

import SwiftUI
import Kingfisher

/// CoveView: Displays the feed for a specific cove, including cove details and events.
struct CoveView: View {
    enum Tab: Int, CaseIterable {
        case events, members
        var title: String {
            switch self {
            case .events: return "events"
            case .members: return "members"
            }
        }
    }
    
    @ObservedObject var viewModel: CoveModel
    let coveId: String
    @EnvironmentObject var appController: AppController
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: Tab = .events
    
    // TODO: admin can update cove cover photo 
    
    var body: some View {
        ZStack {
            Colors.faf8f4.ignoresSafeArea()
            
            if viewModel.isLoading && viewModel.events.isEmpty {
                VStack(spacing: 16) {
                    ProgressView()
                        .tint(Colors.primaryDark)
                    Text("loading your cove...")
                        .font(.LibreBodoni(size: 16))
                        .foregroundColor(Colors.primaryDark)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let cove = viewModel.cove {
                VStack(spacing: 0) {
                    // Fixed header (stationary, long press to refresh cove details - 5 hour cache)
                    CoveHeaderView(cove: cove, 
                                 onBackTapped: { dismiss() },
                                 isRefreshing: viewModel.isRefreshingCoveDetails,
                                 onRefresh: {
                        await withCheckedContinuation { continuation in
                            viewModel.refreshCoveDetails()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                                continuation.resume()
                            })
                        }
                    })
                    .background(Colors.faf8f4)
                    
                    // Top Tabs
                    PillTabBar(
                        titles: Tab.allCases.map { $0.title },
                        selectedIndex: Binding(
                            get: { selectedTab.rawValue },
                            set: { selectedTab = Tab(rawValue: $0) ?? .events }
                        )
                    )
                    .padding(16)
                    
                    // Tab Content
                    ZStack {
                        switch selectedTab {
                        case .events:
                            CoveEventsView(viewModel: viewModel) {
                                // Refreshes events only - header stays fixed
                                await withCheckedContinuation { continuation in
                                    viewModel.refreshEvents()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                                        continuation.resume()
                                    })
                                }
                            }
                        case .members:
                            CoveMembersView(viewModel: viewModel) {
                                // Refreshes members data
                                await withCheckedContinuation { continuation in
                                    viewModel.refreshMembers()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                                        continuation.resume()
                                    })
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else if let error = viewModel.errorMessage {
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
            }
            
            // Floating Action Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    FloatingActionView(coveId: coveId)
                        .padding(.trailing, 24)
                        .padding(.bottom, 30) 
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            viewModel.fetchCoveDetailsIfStale(coveId: coveId)
        }
        .onChange(of: selectedTab) { _, newTab in
            if newTab == .members {
                // Fetch members when members tab is selected
                viewModel.fetchCoveMembers(coveId: coveId)
            }
        }
        .onDisappear {
            // Cancel any ongoing requests when view disappears
            viewModel.cancelRequests()
        }
        .alert("error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("ok") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

#Preview {
    CoveView(viewModel: CoveModel(), coveId: "1")
}
