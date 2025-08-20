import SwiftUI

struct FriendsTabView: View {
    enum Tab: Int, CaseIterable {
        case friends, mutuals, requests
        var title: String {
            switch self {
            case .friends: return "friends"
            case .mutuals: return "mutuals"
            case .requests: return "requests"
            }
        }
    }

    @State private var selectedTab: Tab = .mutuals
    @EnvironmentObject var appController: AppController

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header (always visible only at the root level of this stack)
                CoveBannerView()

                // Top Tabs with external badge overlay
                ZStack(alignment: .topLeading) {
                    PillTabBar(
                        titles: Tab.allCases.map { $0.title },
                        selectedIndex: Binding(
                            get: { selectedTab.rawValue },
                            set: { selectedTab = Tab(rawValue: $0) ?? .mutuals }
                        ),
                        badges: [false, false, false] // handled by external overlay below
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)

                    // External red dot overlay anchored to the "requests" tab position
                    GeometryReader { geo in
                        let tabCount = CGFloat(Tab.allCases.count)
                        let spacing: CGFloat = 8
                        let totalSpacing = max(tabCount - 1, 0) * spacing
                        let tabWidth = (geo.size.width - totalSpacing) / max(tabCount, 1)
                        // Index for requests tab is 2 (zero-based)
                        let idx: CGFloat = 2
                        let x = idx * (tabWidth + spacing) + tabWidth - 12 // 12pt inset from right edge
                        let y: CGFloat = 2

                        if appController.requestsViewModel.requests.count > 0 {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 10, height: 10)
                                .offset(x: x, y: y)
                                .allowsHitTesting(false)
                        }
                    }
                    .frame(height: 32) // match PillTabBar height
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
                    .allowsHitTesting(false)
                }

                // Tab Content (lists)
                ZStack {
                    switch selectedTab {
                    case .friends:
                        FriendsView()
                    case .mutuals:
                        MutualsView()
                    case .requests:
                        RequestsView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Colors.faf8f4)
            }
            .ignoresSafeArea(edges: .bottom)
            .background(Colors.faf8f4)
            .navigationBarBackButtonHidden()
            .onAppear {
                // Load requests if not already loaded
                appController.requestsViewModel.loadNextPageIfStale()
            }
        }
    }
}

#Preview {
    FriendsTabView()
        .environmentObject(AppController.shared)
}
