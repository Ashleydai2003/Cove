//
//  HomeView.swift
//  Cove
//
//  Created by Ananya Agarwal

import SwiftUI

let tabIconSize: CGFloat = 10

struct HomeView: View {
    @State private var tabSelection = 1
    @EnvironmentObject var appController: AppController
    
    // TODO: add indicator on which tab is chosen atm
    var body: some View {
        TabView(selection: $tabSelection) {
            
            UpcomingEventsView()
                .tag(1)
                .tabItem {
                    Image("tab2")
                        .renderingMode(
                            .original)
                }
            
            CalendarView()
                .tag(2)
                .tabItem {
                    Image("calendar").renderingMode(.original)
                }
            
            FeedView()
                .tag(3)
                .tabItem {
                    Image("cove").renderingMode(.original)
                }
            
            FriendsView()
                .tag(4)
                // TODO: Change default image/connect to backend
                .tabItem {
                    Image("friends").renderingMode(.original)
                }
            
            ProfileView()
                .tag(5)
                .tabItem {
                    if let profileImage = appController.profileModel.profileImage {
                        Image(uiImage: profileImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 28, height: 28)
                            .clipShape(Circle())
                            .clipped()
                    } else {
                        Image("tab4")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 28, height: 28)
                            .clipShape(Circle())
                            .clipped()
                    }
                }
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
