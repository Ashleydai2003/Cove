//
//  EventMembersView.swift
//  Cove
//
//  Created by Ananya Agarwal

import SwiftUI

struct EventMembersView: View {
    
    /// App controller for managing navigation and shared state
    @EnvironmentObject var appController: AppController
    
    var body: some View {
        ZStack {
            Colors.faf8f4.ignoresSafeArea()
         
            VStack {
                // Back button
                HStack {
                    Button {
                        appController.path.removeLast()
                    } label: {
                        Images.backArrow
                    }
                    
                    Spacer()
                    
                    Image("standford-icn")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .padding(.leading, -16)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                
                
                Text("stanford")
                    .foregroundStyle(Colors.primaryDark)
                    .font(.LibreBodoniBold(size: 25))
                
                Text("134 members")
                    .foregroundStyle(Color.black)
                    .font(.LibreBodoni(size: 11))
                
                HStack(spacing: 22) {
                    
                    Button {
                        
                    } label: {
                        Text("+ invite")
                            .foregroundStyle(Color.white)
                            .font(.LibreBodoniSemiBold(size: 14))
                            .padding(.horizontal, 24)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Colors.primaryDark)
                            )
                    }
                    
                    Button {
                        
                    } label: {
                        Text("host event")
                            .foregroundStyle(Color.white)
                            .font(.LibreBodoniSemiBold(size: 14))
                            .padding(.horizontal, 24)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Colors.primaryDark)
                            )
                    }
                }
                
                Spacer(minLength: 24)
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        
                        ForEach((1...10), id: \.self) { index in
                            HStack {
                                Images.profilePlaceholder
                                    .resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: 80, maxHeight: 80)
                                    .clipShape(Circle())
                                
                                Text("angela nguyen")
                                    .foregroundStyle(Color.black)
                                    .font(.LibreBodoni(size: 16))
                                
                                Spacer()
                                
                                Button {
                                    
                                } label: {
                                    Text("message")
                                        .foregroundStyle(Color.white)
                                        .font(.LibreBodoniSemiBold(size: 14))
                                        .padding(.horizontal, 24)
                                        .padding(.vertical, 4)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(Colors.primaryDark)
                                        )
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                        
                    }
                }
            }
        }
        .navigationBarBackButtonHidden()
        
    }
}

#Preview {
    EventMembersView()
}
