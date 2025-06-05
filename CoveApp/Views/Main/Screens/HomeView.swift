//
//  HomeView.swift
//  Cove
//
//  Created by Ananya Agarwal

import SwiftUI

let tabIconSize: CGFloat = 10

struct HomeView: View {
    @State private var tabSelection = 1
    
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
                .tabItem {
                    Image("friends").renderingMode(.original)
                }
            
            ProfileView()
                .tag(5)
                .tabItem {
//                    if let imageData = UserDefaults.standard.data(forKey: "user_profile_image"), let image = UIImage(data: imageData) {
//                        Image(uiImage: image)
//                            .resizable()
//                            .aspectRatio(contentMode: .fill)
//                            .frame(width: 28, height: 28)
//                            .clipShape(Circle())
//                            .clipped()
//                    } else {
                        Image("tab4")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 28, height: 28)
                            .clipShape(Circle())
                            .clipped()
//                    }
                }
        }
        .onAppear(perform: {
            
        })
        .navigationBarBackButtonHidden()
    }
}

#Preview {
    HomeView()
}
