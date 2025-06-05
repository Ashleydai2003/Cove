//
//  FeedView.swift
//  Cove
//
//  Created by Ananya Agarwal
import SwiftUI

struct FeedView: View {
    
    /// App controller for managing navigation and shared state
    @EnvironmentObject var appController: AppController
    
    var body: some View {
        ZStack {
            Colors.faf8f4.ignoresSafeArea()
        
            ScrollView(.vertical, showsIndicators: false) {
                VStack {
                    
                    Image("standford-icn")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .padding(.top, 10)
                    
                    Text("stanford")
                        .foregroundStyle(Colors.primaryDark)
                        .font(.LibreBodoniBold(size: 25))
                    
                    Button {
                        appController.path.append(.membersList)
                    } label: {
                        Text("134 members")
                            .foregroundStyle(Color.black)
                            .font(.LibreBodoni(size: 11))
                    }

                    HStack {
                        Button {
                            
                        } label: {
                            Text("+")
                                .foregroundStyle(Color.white)
                                .font(.LibreBodoniBold(size: 20))
                        }

                        VStack(spacing: 0) {
                            Text("host")
                                .foregroundStyle(Color.white)
                                .font(.LibreBodoniSemiBold(size: 14))
                                .padding(.horizontal, 24)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Colors.primaryDark)
                                )
                            
                            Text("event")
                                .foregroundStyle(Color.white)
                                .font(.LibreBodoniSemiBold(size: 14))
                        }
                        .padding(.trailing, 20)
                        
                    }
                    
                    VStack(alignment: .leading) {
                        
                        HStack {
                            HStack(spacing: 5) {
                                Text("@stanfordalumni")
                                    .foregroundStyle(Color.black)
                                    .font(.LibreBodoniSemiBold(size: 12))
                                Image(systemName: "checkmark.circle")
                                    .foregroundStyle(Color.black)
                                    .font(.LibreBodoniSemiBold(size: 12))
                            }
                            
                            Spacer()
                            
                            Text("18hr")
                                .foregroundStyle(Color.black)
                                .font(.LibreBodoniSemiBold(size: 12))
                        }
                        
                        Image("profile-activity-1")
                            .resizable()
                            .scaledToFill()
                            .frame(height: 192)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .clipped()
                        
                        Text("alumni happy hour mixer on monday 5/14 at left door. rsvp at coveapp.co")
                            .foregroundStyle(Color.black)
                            .font(.LibreBodoniSemiBold(size: 12))
                            .multilineTextAlignment(.leading)
                        
                        HStack {
                            Text("@stanfordalumni")
                                .foregroundStyle(Color.black)
                                .font(.LibreBodoniSemiBold(size: 12))
                            
                            Spacer()
                            
                            Text("1d")
                                .foregroundStyle(Color.black)
                                .font(.LibreBodoniSemiBold(size: 12))
                        }
                        .padding(.top, 10)
                        
                        Text("hoping to find a group of stanford alumni who want to build a volunteering club")
                            .foregroundStyle(Color.black)
                            .font(.LibreBodoniSemiBold(size: 12))
                            .frame(maxWidth: .infinity)
                            .padding([.horizontal, .vertical], 10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(.white)
                            )
                        
                        HStack {
                            HStack(spacing: 5) {
                                Text("@stanfordalumni")
                                    .foregroundStyle(Color.black)
                                    .font(.LibreBodoniSemiBold(size: 12))
                                Image(systemName: "checkmark.circle")
                                    .foregroundStyle(Color.black)
                                    .font(.LibreBodoniSemiBold(size: 12))
                            }
                            
                            Spacer()
                            
                            Text("3d")
                                .foregroundStyle(Color.black)
                                .font(.LibreBodoniSemiBold(size: 12))
                        }
                        .padding(.top, 10)
                        
                        Image("profile-activity-1")
                            .resizable()
                            .scaledToFill()
                            .frame(height: 192)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .clipped()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 10)
                   
                    Spacer(minLength: 16)
                }
            }
            
        }
        .navigationBarBackButtonHidden()
        
    }
}

#Preview {
    FeedView()
}
