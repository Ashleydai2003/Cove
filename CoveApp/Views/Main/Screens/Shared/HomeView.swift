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
                        .animation(nil, value: selectedTab)
                } else {
                    // Show default placeholder only if not loading
                    Image("default_user_pfp")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: 40, maxHeight: 40)
                        .clipShape(Circle())
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

            // Tab bar - conditionally shown based on global flag so full-screen views can hide it
            if appController.showTabBar {
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
    }
}

#Preview {
    HomeView()
        .environmentObject(AppController.shared)
}
