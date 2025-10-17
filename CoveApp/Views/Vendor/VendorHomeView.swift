//
//  VendorHomeView.swift
//  Cove
//
//  Main vendor app view with custom tab bar
//

import SwiftUI

struct VendorHomeView: View {
    @EnvironmentObject var vendorController: VendorController
    @State private var selectedTab: Int = 1
    @State private var showingUserProfile: Bool = false
    @State private var eventsPath = NavigationPath()
    @State private var profilePath = NavigationPath()
    
    var body: some View {
        ZStack {
            Colors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Content Area
                ZStack {
                    if selectedTab == 1 {
                        VendorEventsView(navigationPath: $eventsPath)
                    } else if selectedTab == 2 {
                        VendorOrganizationProfileView(
                            showingUserProfile: $showingUserProfile,
                            navigationPath: $profilePath
                        )
                    }
                }
                
                // Custom Tab Bar
                VendorTabBarView(selectedTab: $selectedTab)
            }
        }
        .sheet(isPresented: $showingUserProfile) {
            VendorUserProfileView()
        }
    }
}

// MARK: - Custom Tab Bar View
struct VendorTabBarView: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        HStack {
            Spacer()
            
            // Events Tab
            Button(action: { selectedTab = 1 }) {
                Image(selectedTab == 1 ? "calendar_selected" : "calendar_unselected")
                    .tabBarIcon(isSelected: selectedTab == 1, isMiddleButton: false)
                    .animation(.none, value: selectedTab)
                    .padding(.top, 2)
            }
            .frame(maxWidth: 36, maxHeight: 36)
            
            Spacer()
            
            // Profile Tab
            Button(action: { selectedTab = 2 }) {
                Image(selectedTab == 2 ? "pfp_selected" : "pfp_unselected")
                    .tabBarIcon(isSelected: selectedTab == 2, isMiddleButton: false)
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


