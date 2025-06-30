//
//  UpcomingEventsView.swift
//  Cove
//
//  Created by Ananya Agarwal
import SwiftUI

// TODO: This view is being scrapped and redesigned
struct UpcomingEventsView: View {
    
    @EnvironmentObject var appController: AppController
    
    var body: some View {
        ZStack {
            Colors.faf8f4.ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("cove")
                    .font(.LibreBodoni(size: 70))
                    .foregroundColor(Colors.primaryDark)
                    .frame(height: 70)
                
                Spacer()
                
                VStack(spacing: 16) {
                    Image(systemName: "hammer.fill")
                        .font(.system(size: 60))
                        .foregroundColor(Colors.primaryDark)
                    
                    Text("coming soon")
                        .font(.LibreBodoniBold(size: 24))
                        .foregroundColor(Colors.primaryDark)
                    
                    Text("upcoming events view is being redesigned")
                        .font(.LibreBodoni(size: 16))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .navigationBarBackButtonHidden()
    }
}

#Preview {
    UpcomingEventsView()
        .environmentObject(AppController.shared)
}

