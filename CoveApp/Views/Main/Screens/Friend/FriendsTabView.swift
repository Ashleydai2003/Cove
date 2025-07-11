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

                // Top Tabs
                PillTabBar(
                    titles: Tab.allCases.map { $0.title },
                    selectedIndex: Binding(
                        get: { selectedTab.rawValue },
                        set: { selectedTab = Tab(rawValue: $0) ?? .mutuals }
                    )
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 10)
                
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
        }
    }
}

#Preview {
    FriendsTabView()
        .environmentObject(AppController.shared)
} 