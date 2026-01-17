//
//  PlacetobeView.swift
//  Cove
//
//  Place to be view for the home tab
//

import SwiftUI

struct PlacetobeView: View {
    @Binding var navigationPath: NavigationPath
    @EnvironmentObject var appController: AppController
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                Colors.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Cove banner at top
                    CoveBannerView()
                    
                    // Main content
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 32) {
                            // Clean text header above image
                            VStack(spacing: 8) {
                                Text("the place to be...")
                                    .font(.LibreBodoniItalic(size: 16))
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                                
                                Text("golden gate park concert")
                                    .font(.LibreBodoniBold(size: 24))
                                    .foregroundColor(Colors.primaryDark)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 20)
                            
                            // Large immersive image - no overlays, clean and minimal
                            Image("Placetobeholder")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: .infinity, maxHeight: 400)
                                .clipped()
                                .cornerRadius(16)
                                .padding(.horizontal, 24)
                            
                            // Event details below image
                            VStack(spacing: 8) {
                                Text("this saturday 7pm")
                                    .font(.LibreBodoniBold(size: 18))
                                    .foregroundColor(Colors.primaryDark)
                                    .multilineTextAlignment(.center)
                                
                                Text("3199 Fillmore St San Francisco")
                                    .font(.LibreBodoni(size: 16))
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 16)
                            
                            // Descriptive blurb
                            Text("show up in your dancing shoes and bring your friends, the city is coming out for live music, good vibes, and a stunning sunset.")
                                .font(.LibreBodoni(size: 15))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .lineSpacing(2)
                                .padding(.horizontal, 32)
                                .padding(.top, 10)
                            
                            Spacer(minLength: 20)
                        }
                    }
                }
            }
        }
        .navigationBarBackButtonHidden()
    }
}

#Preview {
    PlacetobeView(navigationPath: .constant(NavigationPath()))
        .environmentObject(AppController.shared)
}
