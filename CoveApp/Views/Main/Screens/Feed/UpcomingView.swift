//
//  UpcomingView.swift
//  Cove
//

import SwiftUI

// MARK: - UpcomingView
struct UpcomingView: View {
    
    @EnvironmentObject var appController: AppController
    @ObservedObject private var upcomingFeed: UpcomingFeed
    
    init() {
        self._upcomingFeed = ObservedObject(wrappedValue: AppController.shared.upcomingFeed)
    }
    
    var body: some View {
        ZStack {
            Colors.faf8f4
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 5) {
                    contentView
                    Spacer(minLength: 20)
                }
            }
            .refreshable {
                await withCheckedContinuation { continuation in
                    upcomingFeed.refreshUpcomingEvents {
                        continuation.resume()
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            upcomingFeed.fetchUpcomingEventsIfStale()
        }
        .onDisappear {
            upcomingFeed.cancelRequests()
        }
        .alert("error", isPresented: errorBinding) {
            Button("ok") { upcomingFeed.errorMessage = nil }
        } message: {
            Text(upcomingFeed.errorMessage ?? "")
        }
    }
    
    // MARK: - Computed Properties
    
    private var errorBinding: Binding<Bool> {
        Binding(
            get: { upcomingFeed.errorMessage != nil },
            set: { if !$0 { upcomingFeed.errorMessage = nil } }
        )
    }
    
    @ViewBuilder
    private var contentView: some View {
        if upcomingFeed.isLoading && upcomingFeed.events.isEmpty {
            LoadingStateView()
        } else if let error = upcomingFeed.errorMessage {
            ErrorStateView(message: error)
        } else if upcomingFeed.events.isEmpty {
            EmptyStateView()
        } else {
            EventsListView()
        }
    }
}

// MARK: - Loading State
private struct LoadingStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(Colors.primaryDark)
            Text("loading your events...")
                .font(.LibreBodoni(size: 16))
                .foregroundColor(Colors.primaryDark)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(minHeight: UIScreen.main.bounds.height - 200)
    }
}

// MARK: - Error State
private struct ErrorStateView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            
            Text(message)
                .font(.LibreBodoni(size: 16))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(minHeight: UIScreen.main.bounds.height - 200)
    }
}

// MARK: - Empty State
private struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            
            Text("no upcoming events")
                .font(.LibreBodoni(size: 16))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(minHeight: UIScreen.main.bounds.height - 200)
    }
}

// MARK: - Events List
private struct EventsListView: View {
    @ObservedObject private var upcomingFeed: UpcomingFeed
    
    init() {
        self._upcomingFeed = ObservedObject(wrappedValue: AppController.shared.upcomingFeed)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(upcomingFeed.events.enumerated()), id: \.element.id) { idx, event in
                EventSummaryView(event: event, type: .feed)
                    .padding(.horizontal, 20)
                    .onAppear {
                        loadMoreIfNeeded(at: idx)
                    }
            }
            
            if upcomingFeed.isLoading && !upcomingFeed.events.isEmpty {
                LoadingIndicatorView()
            }
        }
    }
    
    private func loadMoreIfNeeded(at index: Int) {
        if index == upcomingFeed.events.count - 1 {
            upcomingFeed.loadMoreEventsIfNeeded()
        }
    }
}

// MARK: - Loading Indicator
private struct LoadingIndicatorView: View {
    var body: some View {
        HStack {
            Spacer()
            ProgressView()
                .tint(Colors.primaryDark)
            Spacer()
        }
        .padding(.vertical, 16)
    }
}

// MARK: - Preview
struct UpcomingView_Previews: PreviewProvider {
    static var previews: some View {
        UpcomingView()
            .environmentObject(AppController.shared)
    }
} 