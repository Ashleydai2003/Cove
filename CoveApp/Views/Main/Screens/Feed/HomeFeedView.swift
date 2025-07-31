import SwiftUI

struct HomeFeedView: View {
    enum Tab: Int, CaseIterable {
        case upcoming, discover
        var title: String {
            switch self {
            case .upcoming: return "upcoming"
            case .discover: return "discover"
            }
        }
    }

    @State private var selectedTab: Tab = .upcoming
    @EnvironmentObject var appController: AppController

    var body: some View {
        NavigationStack {
            ZStack {
                Colors.faf8f4
                    .ignoresSafeArea()

        VStack(spacing: 0) {
            // Header
            CoveBannerView()

            // Top Tabs
            PillTabBar(
                titles: Tab.allCases.map { $0.title },
                selectedIndex: Binding(
                    get: { selectedTab.rawValue },
                    set: { selectedTab = Tab(rawValue: $0) ?? .upcoming }
                )
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 10)

            // Tab Content
            ZStack {
                switch selectedTab {
                case .upcoming:
                    UpcomingView()
                case .discover:
                    DiscoverView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationDestination(for: String.self) { eventId in
                // Find the event in our feed data to get the cover photo
                let upcomingEvent = appController.upcomingFeed.items.first { item in
                    switch item {
                    case .event(let event):
                        return event.id == eventId
                    case .post:
                        return false
                    }
                }
                
                // Extract the cover photo if it's an event
                let coverPhoto: CoverPhoto?
                switch upcomingEvent {
                case .event(let event):
                    coverPhoto = event.coveCoverPhoto
                case .post, .none:
                    coverPhoto = nil
                }
                
                return EventPostView(eventId: eventId, coveCoverPhoto: coverPhoto)
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .navigationBarBackButtonHidden()
    }
}

#Preview {
    HomeFeedView()
        .environmentObject(AppController.shared)
}
