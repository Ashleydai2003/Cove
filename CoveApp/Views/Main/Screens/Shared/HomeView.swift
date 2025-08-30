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
        let baseSize: CGFloat = isMiddleButton ? 32 : 28
        let selectedSize: CGFloat = isMiddleButton ? 34 : 30

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
                    .padding(.top, 2)
            }
            .frame(maxWidth: 36, maxHeight: 36)

            Spacer()

            // Chat Tab
            Button(action: { selectedTab = 2 }) {
                Image(selectedTab == 2 ? "chat_selected" : "chat_unselected")
                    .tabBarIcon(isSelected: selectedTab == 2, isMiddleButton: false)
                    .animation(.none, value: selectedTab)
                    .padding(.top, 2)
            }
            .frame(maxWidth: 36, maxHeight: 36)

            Spacer()

            // Cove Tab
            Button(action: { selectedTab = 3 }) {
<<<<<<< HEAD
                ZStack(alignment: .topTrailing) {
                    Image(selectedTab == 3 ? "cove_selected" : "cove_unselected")
                        .tabBarIcon(isSelected: selectedTab == 3, isMiddleButton: true)
                        .animation(.none, value: selectedTab)
                        .padding(.top, 2)
                    if appController.inboxViewModel.hasUnopenedInvites {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 10, height: 10)
                            .offset(x: 6, y: -6)
                    }
                }
=======
                Image(selectedTab == 3 ? "cove_selected" : "cove_unselected")
                    .tabBarIcon(isSelected: selectedTab == 3, isMiddleButton: true)
                    .animation(.none, value: selectedTab)
>>>>>>> 568699e726e7b9fa17d42b4a958b9f87fa6c0f5e
            }
            .frame(maxWidth: 40, maxHeight: 40)

            Spacer()

            // Friends Tab
            Button(action: { selectedTab = 4 }) {
                ZStack(alignment: .topTrailing) {
                    Image(selectedTab == 4 ? "calendar_selected" : "calendar_unselected")
                        .tabBarIcon(isSelected: selectedTab == 4, isMiddleButton: true)
                        .animation(.none, value: selectedTab)
                        .padding(.top, 2)
                    if !appController.requestsViewModel.requests.isEmpty {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 10, height: 10)
                            .offset(x: 6, y: -6)
                    }
                }
            }
            .frame(maxWidth: 40, maxHeight: 40)

            Spacer()

            // Profile Tab
            Button(action: { selectedTab = 5 }) {
                Image(selectedTab == 5 ? "pfp_selected" : "pfp_unselected")
                    .tabBarIcon(isSelected: selectedTab == 5, isMiddleButton: false)
                    .animation(.none, value: selectedTab)
                    .padding(.top, 2)
            }
            .frame(maxWidth: 36, maxHeight: 36)

            Spacer()
        }
        .padding(.vertical, 6)
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
        ZStack {
            Colors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                ZStack {
                    // Main content area - switch instead of TabView to prevent rebuilding
                    switch tabSelection {
                    case 1: UpcomingView()
                    case 2: ChatView()
                    case 3: CoveFeedView()
                    case 4: CalendarView()
                    case 5: ProfileView()
                    default: ChatView()
                    }
                }

                // Tab bar - now won't be recreated on tab switches
                TabBarView(selectedTab: $tabSelection)
            }
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
                // Route to an event: pick Calendar tab (4) which knows how to navigate to eventId
                tabSelection = 4
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
        .onReceive(NotificationCenter.default.publisher(for: .navigateToCalendar)) { _ in
            tabSelection = 4
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(AppController.shared)
}

// MARK: - ChatView (placeholder for navbar tab)
struct ChatView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Colors.background.ignoresSafeArea()

                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 40))
                        .foregroundColor(Colors.primaryDark)
                    Text("chat is coming soon!")
                        .font(.LibreBodoniSemiBold(size: 24))
                        .foregroundColor(Colors.primaryDark)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationBarBackButtonHidden()
    }
}