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
    func tabBarIcon(isSelected: Bool = false) -> some View {
        self
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(maxWidth: isSelected ? 43 : 40, maxHeight: isSelected ? 43 : 40)
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
                    .tabBarIcon(isSelected: selectedTab == 1)
                    .animation(nil, value: selectedTab)
            }
            .frame(maxWidth: 50, maxHeight: 50)
            
            Spacer()
            
            // Calendar Tab
            Button(action: { selectedTab = 2 }) {
                Image(selectedTab == 2 ? "calendar_selected" : "calendar_unselected")
                    .tabBarIcon(isSelected: selectedTab == 2)
                    .animation(nil, value: selectedTab)
            }
            .frame(maxWidth: 50, maxHeight: 50)
            
            Spacer()
            
            // Cove Tab
            Button(action: { selectedTab = 3 }) {
                Image(selectedTab == 3 ? "cove_selected" : "cove_unselected")
                    .tabBarIcon(isSelected: selectedTab == 3)
                    .animation(nil, value: selectedTab)
            }
            .frame(maxWidth: 50, maxHeight: 50)
            
            Spacer()
            
            // Friends Tab
            Button(action: { selectedTab = 4 }) {
                Image(selectedTab == 4 ? "friends_selected" : "friends_unselected")
                    .tabBarIcon(isSelected: selectedTab == 4)
                    .animation(nil, value: selectedTab)
            }
            .frame(maxWidth: 50, maxHeight: 50)
            
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
                } else {
                    // TODO: replace with default profile image
                    Image("smiley")
                        .tabBarIcon(isSelected: selectedTab == 5)
                        .overlay(
                            Circle()
                                .stroke(Color(hex: "F5F0E6"), lineWidth: selectedTab == 5 ? 3 : 0)
                        )
                        .animation(nil, value: selectedTab)
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
