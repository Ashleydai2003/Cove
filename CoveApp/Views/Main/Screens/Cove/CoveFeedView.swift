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
    @State private var topTabSelection: CoveTopTabs.Tab = .coves
    @GestureState private var isHorizontalSwiping: Bool = false
    

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
                // Top tabs under safe area
                CoveTopTabs(selected: $topTabSelection)

                // Content switcher with full-area swipe
                ZStack {
                    switch topTabSelection {
                    case .coves:
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
                                        CoveCardView(cove: cove, disableNavigation: isHorizontalSwiping)
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
                    case .people:
                        PeopleInNetworkView()
                    }
                    // FAB - only for verified/admin users and only on coves tab
                    if appController.profileModel.verified && topTabSelection == .coves {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                FloatingActionView(coveId: nil) {
                                    // Optionally refresh coves after creation
                                    coveFeed.refreshUserCoves()
                                }
                                .padding(.trailing, 20)
                                .padding(.bottom, 20)
                            }
                        }
                        .allowsHitTesting(true)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                                withAnimation(.easeInOut(duration: 0.22)) { topTabSelection = .people }
                            } else {
                                withAnimation(.easeInOut(duration: 0.22)) { topTabSelection = .coves }
                            }
                        }
                )
                .overlay(
                    Color.clear
                        .ignoresSafeArea()
                        .allowsHitTesting(isHorizontalSwiping)
                )
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

// MARK: - Cove Top Tabs
private struct CoveTopTabs: View {
    @Binding var selected: Tab
    @Namespace private var underlineNamespace
    @State private var dragTranslation: CGFloat = 0
    @State private var isDragging: Bool = false

    enum Tab { case coves, people }

    var body: some View {
        HStack {
            // Coves tab (left, default)
            Button(action: {
                withAnimation(.easeInOut(duration: 0.22)) { selected = .coves }
            }) {
                VStack(spacing: 6) {
                    Text("coves")
                        .font(.LibreBodoni(size: 16))
                        .foregroundStyle(Colors.primaryDark)
                    Group {
                        if selected == .coves {
                            Capsule()
                                .fill(Colors.primaryDark)
                                .matchedGeometryEffect(id: "coveTabUnderline", in: underlineNamespace)
                        } else {
                            Color.clear
                        }
                    }
                    .frame(height: 1)
                    .opacity(isDragging ? 0 : 1)
                }
            }
            .anchorPreference(key: CoveTabBoundsKey.self, value: .bounds) { ["coves": $0] }

            Spacer()

            // People tab (right)
            Button(action: {
                withAnimation(.easeInOut(duration: 0.22)) { selected = .people }
            }) {
                VStack(spacing: 6) {
                    Text("people")
                        .font(.LibreBodoni(size: 16))
                        .foregroundStyle(Colors.primaryDark)
                    Group {
                        if selected == .people {
                            Capsule()
                                .fill(Colors.primaryDark)
                                .matchedGeometryEffect(id: "coveTabUnderline", in: underlineNamespace)
                        } else {
                            Color.clear
                        }
                    }
                    .frame(height: 1)
                    .opacity(isDragging ? 0 : 1)
                }
            }
            .anchorPreference(key: CoveTabBoundsKey.self, value: .bounds) { ["people": $0] }
        }
        .padding(.horizontal, 30)
        .padding(.top, 6)
        .padding(.bottom, 8)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 8)
                .onChanged { value in
                    isDragging = true
                    dragTranslation = value.translation.width
                }
                .onEnded { value in
                    isDragging = false
                    let endTranslation = value.translation.width
                    if endTranslation < -30 {
                        withAnimation(.easeInOut(duration: 0.22)) { selected = .people }
                    } else if endTranslation > 30 {
                        withAnimation(.easeInOut(duration: 0.22)) { selected = .coves }
                    }
                    dragTranslation = 0
                }
        )
        .overlayPreferenceValue(CoveTabBoundsKey.self) { prefs in
            GeometryReader { proxy in
                if let leftAnchor = prefs["coves"], let rightAnchor = prefs["people"] {
                    let leftFrame = proxy[leftAnchor]
                    let rightFrame = proxy[rightAnchor]
                    let leftCenterX = leftFrame.midX
                    let rightCenterX = rightFrame.midX
                    let distance = rightCenterX - leftCenterX
                    let base: CGFloat = (selected == .coves) ? 0 : 1
                    let dragProgress: CGFloat = (isDragging && distance != 0) ? (-dragTranslation / distance) : 0
                    let t = min(max(base + dragProgress, 0), 1)
                    let width = leftFrame.width + (rightFrame.width - leftFrame.width) * t
                    let centerX = leftCenterX + distance * t
                    let underlineY = max(leftFrame.maxY, rightFrame.maxY) + 1

                    Capsule()
                        .fill(Colors.primaryDark)
                        .frame(width: width, height: 1)
                        .position(x: centerX, y: underlineY)
                        .animation(.easeInOut(duration: 0.12), value: selected)
                        .opacity(isDragging ? 1 : 0)
                }
            }
        }
    }
}

// Preference key for capturing tab bounds in Cove tabs
private struct CoveTabBoundsKey: PreferenceKey {
    static var defaultValue: [String: Anchor<CGRect>] = [:]
    static func reduce(value: inout [String: Anchor<CGRect>], nextValue: () -> [String: Anchor<CGRect>]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}
#Preview {
    CoveFeedView()
        .environmentObject(AppController.shared)
}
