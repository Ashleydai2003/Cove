//
//  HomeView.swift
//  Cove
//
//  Created by Ananya Agarwal

import SwiftUI
import Kingfisher

let tabIconSize: CGFloat = 10

// MARK: - Image Extension for Tab Bar Icons
extension Image {
    func tabBarIcon(isSelected: Bool = false, isMiddleButton: Bool = false) -> some View {
        let baseSize: CGFloat = isMiddleButton ? 45 : 40
        let selectedSize: CGFloat = isMiddleButton ? 48 : 43

        return self
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(maxWidth: isSelected ? selectedSize : baseSize, maxHeight: isSelected ? selectedSize : baseSize)
    }
}

// NOTE: We are using a custom tab bar because the default tab bar is not customizable with the profile image icon

// MARK: - Custom Tab Bar View
struct TabBarView: View {
    @Binding var selectedTab: Int
    @EnvironmentObject var appController: AppController

    var body: some View {
        HStack {
            Spacer()

            // Home Tab
            Button(action: { selectedTab = 1 }) {
                Image(selectedTab == 1 ? "home_selected" : "home_unselected")
                    .tabBarIcon(isSelected: selectedTab == 1, isMiddleButton: false)
                    .animation(.none, value: selectedTab)
            }
            .frame(maxWidth: 50, maxHeight: 50)

            Spacer()

            // Calendar Tab
            Button(action: { selectedTab = 2 }) {
                Image(selectedTab == 2 ? "calendar_selected" : "calendar_unselected")
                    .tabBarIcon(isSelected: selectedTab == 2, isMiddleButton: false)
                    .animation(.none, value: selectedTab)
            }
            .frame(maxWidth: 50, maxHeight: 50)

            Spacer()

            // Cove Tab
            Button(action: { selectedTab = 3 }) {
                Image(selectedTab == 3 ? "cove_selected" : "cove_unselected")
                    .tabBarIcon(isSelected: selectedTab == 3, isMiddleButton: true)
                    .animation(.none, value: selectedTab)
            }
            .frame(maxWidth: 56, maxHeight: 56)

            Spacer()

            // Friends Tab
            Button(action: { selectedTab = 4 }) {
                ZStack(alignment: .topTrailing) {
                    Image(selectedTab == 4 ? "friends_selected" : "friends_unselected")
                        .tabBarIcon(isSelected: selectedTab == 4, isMiddleButton: true)
                        .animation(.none, value: selectedTab)
                    if !appController.requestsViewModel.requests.isEmpty {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 10, height: 10)
                            .offset(x: 6, y: -6)
                    }
                }
            }
            .frame(maxWidth: 56, maxHeight: 56)

            Spacer()

            // Profile Tab with KFImage
            Button(action: { selectedTab = 5 }) {
                if let profileImage = appController.profileModel.profileUIImage {
                    Image(uiImage: profileImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: 40, maxHeight: 40)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color(hex: "F5F0E6"), lineWidth: selectedTab == 5 ? 3 : 0)
                        )
                        .animation(nil, value: selectedTab)
                } else if appController.profileModel.isProfileImageLoading {
                    // Show loading state with proper circular shape
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(maxWidth: 40, maxHeight: 40)
                        .overlay(
                            ProgressView()
                                .scaleEffect(0.7)
                                .tint(Color.white)
                        )
                        .overlay(
                            Circle()
                                .stroke(Color(hex: "F5F0E6"), lineWidth: selectedTab == 5 ? 3 : 0)
                        )
                        .animation(.none, value: selectedTab)
                } else {
                    // Show default placeholder only if not loading
                    Image("default_user_pfp")
                        .tabBarIcon(isSelected: selectedTab == 5, isMiddleButton: false)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color(hex: "F5F0E6"), lineWidth: selectedTab == 5 ? 3 : 0)
                        )
                        .animation(.none, value: selectedTab)
                }
            }
            .frame(maxWidth: 50, maxHeight: 50)

            Spacer()
        }
        .padding(.vertical, 8)
        .background(Color(hex: "5E1C1D"))
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color.gray.opacity(0.3)),
            alignment: .top
        )
    }
}

struct HomeView: View {
    @State private var tabSelection = 1
    @State private var showInboxAutomatically = false
    @EnvironmentObject var appController: AppController

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                // Main content area - switch instead of TabView to prevent rebuilding
                switch tabSelection {
                case 1: HomeFeedView()
                case 2: CalendarView()
                case 3: CoveFeedView()
                case 4: FriendsTabView()
                case 5: ProfileView()
                default: CalendarView()
                }
            }

            // Tab bar - now won't be recreated on tab switches
            TabBarView(selectedTab: $tabSelection)
        }
        .onAppear(perform: {
            // Set default tab selection
            tabSelection = 1
            Log.debug("🏠 HomeView: onAppear - shouldAutoShowInbox = \(appController.shouldAutoShowInbox)")
            Log.debug("🏠 HomeView: onAppear - inboxViewModel.hasUnopenedInvites = \(appController.inboxViewModel.hasUnopenedInvites)")
            Log.debug("🏠 HomeView: onAppear - inboxViewModel.invites.count = \(appController.inboxViewModel.invites.count)")

            // Check for auto-show inbox in case we missed the initial trigger
            if appController.inboxViewModel.hasUnopenedInvites && !appController.shouldAutoShowInbox {
                Log.debug("🏠 HomeView: Found unopened invites on appear, triggering auto-show")
                appController.shouldAutoShowInbox = true
            }

            // Fallback check after 2 seconds in case initial data loading is still in progress
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                if appController.inboxViewModel.hasUnopenedInvites && !showInboxAutomatically && !appController.shouldAutoShowInbox {
                    Log.debug("🏠 HomeView: Fallback check - found unopened invites, triggering auto-show")
                    appController.shouldAutoShowInbox = true
                }
            }
        })
        .onChange(of: appController.shouldAutoShowInbox) { _, shouldShow in
            Log.debug("🏠 HomeView: shouldAutoShowInbox changed to: \(shouldShow)")
            if shouldShow {
                Log.debug("🏠 HomeView: Setting showInboxAutomatically = true")
                showInboxAutomatically = true
                // Reset the flag so it doesn't show again
                appController.shouldAutoShowInbox = false
            }
        }
        .onChange(of: showInboxAutomatically) { _, show in
            Log.debug("🏠 HomeView: showInboxAutomatically changed to: \(show)")
        }
        .sheet(isPresented: $showInboxAutomatically) {
            InboxView()
        }
        .navigationBarBackButtonHidden()
        .onReceive(NotificationCenter.default.publisher(for: .navigateToEvent)) { note in
            if let eventId = note.userInfo?["eventId"] as? String {
                // Route to an event: pick Calendar tab (2) which knows how to navigate to eventId
                tabSelection = 2
                // Push by setting NavigationStack value via Notification; here we rely on NavigationLink(value:)
                // A minimal approach: store a deep-link on AppController and let the CalendarView pick it up.
                AppController.shared.calendarFeed.navigateToEventId = eventId
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToCove)) { note in
            if let coveId = note.userInfo?["coveId"] as? String {
                tabSelection = 3
                AppController.shared.coveFeed.deepLinkToCoveId = coveId
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToFriends)) { _ in
            tabSelection = 4
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToInbox)) { _ in
            tabSelection = 1
            AppController.shared.shouldAutoShowInbox = true
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(AppController.shared)
}
