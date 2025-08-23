//
//  CoveView.swift
//  Cove
//
//  Created by Ananya Agarwal

import SwiftUI
import Kingfisher

/// CoveView: Displays the feed for a specific cove, including cove details and events.
struct CoveView: View {
    enum Tab: Int, CaseIterable {
        case events, posts, members
        var title: String {
            switch self {
            case .events: return "events"
            case .posts: return "posts"
            case .members: return "members"
            }
        }
    }

    @ObservedObject var viewModel: CoveModel
    let coveId: String
    @EnvironmentObject var appController: AppController
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: Tab = .events
    @GestureState private var isHorizontalSwiping: Bool = false

    // TODO: admin can update cove cover photo

    var body: some View {
        ZStack {
            Colors.background.ignoresSafeArea()

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
                    // Compact info header (centered, smaller square image)
                    CoveInfoHeaderView(
                        cove: cove,
                        onBackTapped: { dismiss() },
                        isRefreshing: viewModel.isRefreshingCoveDetails,
                        onRefresh: {
                            await withCheckedContinuation { continuation in
                                viewModel.refreshCoveDetails()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    continuation.resume()
                                }
                            }
                        }
                    )
                    .background(Colors.background)

                    // Top Tabs (underline-style)
                    CoveDetailTabs(selected: Binding(
                        get: { selectedTab },
                        set: { selectedTab = $0 }
                    ))
                    .padding(.horizontal, 30)
                    .padding(.top, 6)

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
                            .environment(\.isEnabled, !isHorizontalSwiping)
                        case .posts:
                            CovePostsView(viewModel: viewModel) {
                                // Refreshes posts only - header stays fixed
                                await withCheckedContinuation { continuation in
                                    viewModel.refreshPosts()
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
                            .disabled(isHorizontalSwiping)
                        }
                    }
                    .contentShape(Rectangle())
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 16)
                            .updating($isHorizontalSwiping) { value, state, _ in
                                let dx = value.translation.width
                                let dy = value.translation.height
                                if abs(dx) > abs(dy) && abs(dx) > 10 { state = true }
                            }
                            .onEnded { value in
                                let dx = value.translation.width
                                let dy = value.translation.height
                                guard abs(dx) > abs(dy), abs(dx) > 30 else { return }
                                if dx < 0 {
                                    // left swipe → move right
                                    withAnimation(.easeInOut(duration: 0.22)) {
                                        switch selectedTab {
                                        case .events: selectedTab = .posts
                                        case .posts: selectedTab = .members
                                        case .members: break
                                        }
                                    }
                                } else {
                                    // right swipe → move left
                                    withAnimation(.easeInOut(duration: 0.22)) {
                                        switch selectedTab {
                                        case .events: break
                                        case .posts: selectedTab = .events
                                        case .members: selectedTab = .posts
                                        }
                                    }
                                }
                            }
                    )
                    .overlay(
                        Color.clear
                            .ignoresSafeArea()
                            .allowsHitTesting(isHorizontalSwiping)
                    )
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
                    FloatingActionView(coveId: coveId, onEventCreated: {
                        // Refresh both events and posts when something is created
                        viewModel.refreshEvents()
                        viewModel.refreshPosts()
                    })
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
            } else if newTab == .posts {
                // Fetch posts when posts tab is selected
                viewModel.fetchPosts(coveId: coveId)
            }
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

// MARK: - Cove Detail Tabs
private struct CoveDetailTabs: View {
    @Binding var selected: CoveView.Tab
    @Namespace private var underlineNamespace

    var body: some View {
        HStack {
            Button(action: { withAnimation(.easeInOut(duration: 0.22)) { selected = .events } }) {
                VStack(spacing: 6) {
                    Text("events")
                        .font(.LibreBodoni(size: 16))
                        .foregroundStyle(Colors.primaryDark)
                    Group {
                        if selected == .events {
                            Capsule()
                                .fill(Colors.primaryDark)
                                .matchedGeometryEffect(id: "coveDetailUnderline", in: underlineNamespace)
                        } else { Color.clear }
                    }
                    .frame(height: 1)
                }
            }

            Spacer()

            Button(action: { withAnimation(.easeInOut(duration: 0.22)) { selected = .posts } }) {
                VStack(spacing: 6) {
                    Text("posts")
                        .font(.LibreBodoni(size: 16))
                        .foregroundStyle(Colors.primaryDark)
                    Group {
                        if selected == .posts {
                            Capsule()
                                .fill(Colors.primaryDark)
                                .matchedGeometryEffect(id: "coveDetailUnderline", in: underlineNamespace)
                        } else { Color.clear }
                    }
                    .frame(height: 1)
                }
            }

            Spacer()

            Button(action: { withAnimation(.easeInOut(duration: 0.22)) { selected = .members } }) {
                VStack(spacing: 6) {
                    Text("members")
                        .font(.LibreBodoni(size: 16))
                        .foregroundStyle(Colors.primaryDark)
                    Group {
                        if selected == .members {
                            Capsule()
                                .fill(Colors.primaryDark)
                                .matchedGeometryEffect(id: "coveDetailUnderline", in: underlineNamespace)
                        } else { Color.clear }
                    }
                    .frame(height: 1)
                }
            }
        }
    }
}

#Preview {
    CoveView(viewModel: CoveModel(), coveId: "1")
}
