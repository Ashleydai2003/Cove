//
//  EventInvitesView.swift
//  Cove
//
//  Created by Ananya Agarwal

import SwiftUI

struct YourInvitesView: View {
    
    /// App controller for managing navigation and shared state
    @EnvironmentObject var appController: AppController
    
    var body: some View {
        ZStack {
            Colors.faf8f4.ignoresSafeArea()
            
            VStack {
                Spacer()
                
                Text("your invites")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Colors.primaryDark)
                    .padding(.bottom, 40)
                    .font(.LibreBodoniMedium(size: 30))
                
                VStack {
                    Text("stanford sf club")
                        .font(.LibreBodoniBold(size: 22))
                        .foregroundStyle(Color.white)
                        .padding()
                    
                    Image("invite-events")
                        .resizable()
                        .scaledToFill()
                        .frame(height: 160)
                        .padding(.horizontal, 6)
                        .clipped()
                    
                    Text("cove’s bio.")
                        .font(.LeagueSpartan(size: 14))
                        .foregroundStyle(Color.white)
                    
                    HStack(spacing: 30) {
                        Spacer()
                        
                        Button {
                            appController.path.append(.home)
                        } label: {
                            Image("invite-reject")
                                .resizable()
                                .frame(width: 44, height: 44)
                        }
                        
                        Button {
                            appController.path.append(.home)
                        } label: {
                            Image("invite-accept")
                                .resizable()
                                .frame(width: 44, height: 44)
                        }
                        
                        Spacer()

                    }
                    .padding(.vertical, 20)
                    
                    
                }
                .background(Colors.primaryDark)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal, 40)
                .rotationEffect(.degrees(2.5))
                
                
                Spacer()
            }
        }
        .navigationBarBackButtonHidden()
    }
}

#Preview {
    YourInvitesView()
}
