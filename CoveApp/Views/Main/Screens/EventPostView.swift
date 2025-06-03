//
//  EventPostView.swift
//  Cove
//
//  Created by Ananya Agarwal
import SwiftUI

struct EventPostView: View {
    
    /// App controller for managing navigation and shared state
    @EnvironmentObject var appController: AppController
    
    var body: some View {
        ZStack {
            Colors.faf8f4.ignoresSafeArea()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    // Back button
                    HStack(alignment: .top) {
//                        Button {
//                            appController.path.removeLast()
//                        } label: {
//                            Images.backArrow
//                        }
//                        .padding(.top, 16)
                        
                        Spacer()
                        
                        Image("add-event-icn")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                        
                        Image("add-event-icn")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                        
                        Spacer()
                    }
                    
                    Text("stanford x harvard happy hour")
                        .foregroundStyle(Colors.primaryDark)
                        .font(.LibreBodoniBold(size: 26))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .multilineTextAlignment(.center)
                    
                    Image("profile-activity-1")
                        .resizable()
                        .scaledToFill()
                        .frame(height: 192)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .clipped()
                    
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Saturday, June 22")
                                .foregroundStyle(Colors.primaryDark)
                                .font(.LibreBodoni(size: 18))
                            Spacer()
                            Text("9PM")
                                .foregroundStyle(Colors.primaryDark)
                                .font(.LibreBodoni(size: 18))
                        }
                        
                        HStack {
                            Image("location-pin")
                                .frame(width: 15, height: 20)
                            
                            Text("3199 Fillmore St San Francisco")
                                .foregroundStyle(Colors.primaryDark)
                                .font(.LibreBodoniBold(size: 16))
                        }
                    }
                    
                    Text("the stanford and harvard alumni clubs are hosting a young alumni happy hour at balboa cafe. come mingle and chat with new friends over espresso martinis. ")
                        .foregroundStyle(Colors.k292929)
                        .font(.LibreBodoni(size: 18))
                        .multilineTextAlignment(.leading)
                    
                    VStack(alignment: .leading) {
                        Text("guest list")
                            .foregroundStyle(Colors.primaryDark)
                            .font(.LibreBodoniBold(size: 18))
                        
                        HStack {
                            ForEach((1...4), id: \.self) { index in
                                Images.profilePlaceholder
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 62, height: 62)
                                    .clipShape(Circle())
                            }
                            
                            Text("+80")
                                .foregroundStyle(Colors.primaryDark)
                                .font(.LibreBodoniBold(size: 10))
                                .padding(.all, 8)
                                .overlay {
                                    Circle()
                                        .stroke(Colors.primaryDark, lineWidth: 1.0)
                                }
                        }
                    }
                    
                    HStack(spacing: 24) {
                        Spacer()
                        
                        Button {
                            
                        } label: {
                            Text("yes")
                                .foregroundStyle(Colors.k070708)
                                .font(.LeagueSpartan(size: 12))
                                .padding(.horizontal, 24)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Colors.kE8DFCB)
                                )
                        }
                        
                        Button {
                            
                        } label: {
                            Text("maybe")
                                .foregroundStyle(Colors.k070708)
                                .font(.LeagueSpartan(size: 12))
                                .padding(.horizontal, 24)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color.white)
                                )
                        }
                        
                        Button {
                            
                        } label: {
                            Text("no")
                                .foregroundStyle(Colors.k070708)
                                .font(.LeagueSpartan(size: 12))
                                .padding(.horizontal, 24)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color.white)
                                )
                        }
                        
                        Spacer()
                    }
                    .padding([.horizontal, .vertical], 16)
                    .background(Colors.primaryDark)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    
                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 24)
                .padding(.top, 10)
            }
        }
        .navigationBarBackButtonHidden()
        
    }
    
}

#Preview {
    EventPostView()
}
