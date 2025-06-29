//
//  HomeView.swift
//  Cove
//
//  Created by Ananya Agarwal

import SwiftUI
import Kingfisher


let tabIconSize: CGFloat = 10

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
                Image("tab2")
                    .renderingMode(.original)
            }
            
            Spacer()
            
            // Calendar Tab
            Button(action: { selectedTab = 2 }) {
                Image("calendar")
                    .renderingMode(.original)
            }
            
            Spacer()
            
            // Cove Tab
            Button(action: { selectedTab = 3 }) {
                Image("cove")
                    .renderingMode(.original)
            }
            
            Spacer()
            
            // Friends Tab
            Button(action: { selectedTab = 4 }) {
                Image("friends")
                    .renderingMode(.original)
            }
            
            Spacer()
            
            // Profile Tab with KFImage
            Button(action: { selectedTab = 5 }) {
                if let profileImage = appController.profileModel.profileUIImage {
                    Image(uiImage: profileImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 28, height: 28)
                        .clipShape(Circle())
                } else {
                    // TODO: replace with default profile image
                    Image("tab4")
                        .renderingMode(.original)
                }
            }
            
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
    @EnvironmentObject var appController: AppController
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                // Main content area - switch instead of TabView to prevent rebuilding
                switch tabSelection {
                case 1: UpcomingEventsView()
                case 2: CalendarView()
                case 3: FeedView()
                case 4: FriendsView()
                case 5: ProfileView()
                default: UpcomingEventsView()
                }
            }

            // Tab bar - now won't be recreated on tab switches
            TabBarView(selectedTab: $tabSelection)
        }
        .onAppear(perform: {
            // Only set to home tab if this is the initial app launch
            // Otherwise, preserve the current tab selection
            if appController.path.isEmpty {
                tabSelection = 1
                appController.previousTabSelection = 1
            } else {
                // Restore the previous tab selection when returning from navigation
                tabSelection = appController.previousTabSelection
            }
        })
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            // Only reset tab selection when app becomes active if we're at the root level
            // This prevents resetting when returning from background while in a sub-navigation
            if appController.path.isEmpty {
                tabSelection = appController.previousTabSelection
            }
        }
        .onChange(of: appController.path) { _, newPath in
            // When navigation path changes (like returning from an event)
            if newPath.isEmpty {
                // We're back at the root level, restore the previous tab
                tabSelection = appController.previousTabSelection
            } else if newPath.last == .home {
                // We're navigating to home, update the previous tab to current selection
                appController.previousTabSelection = tabSelection
            }
        }
        .onChange(of: tabSelection) { _, newTab in
            // Store the current tab selection as previous when user manually changes tabs
            if !appController.path.isEmpty {
                appController.previousTabSelection = newTab
            }
        }
        .onDisappear {
            // Cancel any ongoing requests when HomeView disappears
            appController.profileModel.cancelAllRequests()
        }
        .navigationBarBackButtonHidden()
    }
}

#Preview {
    HomeView()
        .environmentObject(AppController.shared)
}
