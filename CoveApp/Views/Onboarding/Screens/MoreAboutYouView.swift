//
//  MoreAboutYouView.swift
//  Cove
//


import SwiftUI

struct MoreAboutYouView: View {
    
    /// App controller for managing navigation and app state
    @EnvironmentObject var appController: AppController
    
    @State private var job = ""
    @State private var workLocation = ""
    @State private var relationStatus = ""
    @State private var gender = ""
    @State private var interestedInto = ""
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack {
            HStack {
                Button {
                    appController.path.removeLast()
                } label: {
                    Images.backArrow
                }
                Spacer()
            }
            .padding(.top, 10)
            
            Text("more about you")
                .foregroundStyle(Colors.primaryDark)
                .font(.LibreBodoniMedium(size: 40))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 20)
            
            Text("share what you want others to know about you")
                .font(.LeagueSpartan(size: 15))
                .foregroundColor(Colors.k0B0B0B)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    
                    VStack(alignment: .leading, spacing: 12) {
                        
                        HStack(spacing: 10) {
                            Images.moreInfo
                            
                            Text("Gender")
                                .font(.LeagueSpartan(size: 15))
                                .foregroundColor(Colors.k6F6F73)
                        }
                        
                        HStack {
                            
                            RoundedButtonView(title: "female", isSelected: gender == "female") {
                                gender = "female"
                            }
                            
                            RoundedButtonView(title: "male", isSelected: gender == "male") {
                                gender = "male"
                            }
                            
                            RoundedButtonView(title: "other", isSelected: gender == "other") {
                                gender = "other"
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 10) {
                            Images.moreInfo
                            
                            Text("relationship status")
                                .font(.LeagueSpartan(size: 15))
                                .foregroundColor(Colors.k6F6F73)
                        }
                        HStack {
                            
                            RoundedButtonView(title: "single", isSelected: relationStatus == "single") {
                                relationStatus = "single"
                            }
                            
                            RoundedButtonView(title: "taken", isSelected: relationStatus == "taken") {
                                relationStatus = "taken"
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 10) {
                            Images.moreInfo
                            
                            Text("i’m into...")
                                .font(.LeagueSpartan(size: 15))
                                .foregroundColor(Colors.k6F6F73)
                        }
                        HStack {
                            
                            RoundedButtonView(title: "girls", isSelected: interestedInto == "girls") {
                                interestedInto = "girls"
                            }
                            
                            RoundedButtonView(title: "guys", isSelected: interestedInto == "guys") {
                                interestedInto = "guys"
                            }
                            
                            RoundedButtonView(title: "other", isSelected: interestedInto == "other") {
                                interestedInto = "other"
                            }
                        }
                    }
                    
                    VStack {
                        VStack {
                            HStack(spacing: 10) {
                                Image(systemName: "briefcase")
                                    .frame(width: 29, height: 29)
                                    .foregroundStyle(Colors.k6B6B6B)
                                
                                TextField("What you do", text: $job)
                                    .font(.LibreCaslon(size: 15))
                                    .foregroundStyle(Colors.k6F6F73)
                                    .focused($isFocused)
                            }
                            Divider()
                                .frame(height: 2)
                                .background(Color.black.opacity(0.58))
                        }
                        .frame(height: 50)
                        
                        VStack {
                            HStack(spacing: 10) {
                                Images.skyscrapers
                                    .scaledToFit()
                                    .frame(width: 29, height: 29)
                                
                                TextField("Where you work", text: $workLocation)
                                    .font(.LibreCaslon(size: 15))
                                    .foregroundStyle(Colors.k6F6F73)
                                    .focused($isFocused)
                            }
                            Divider()
                                .frame(height: 2)
                                .background(Color.black.opacity(0.58))
                        }
                        .frame(height: 50)
                    }
                }
                .padding(.top, 20)
            }
            
            HStack {
                Spacer()
                Images.smily
                    .resizable()
                    .frame(width: 52, height: 52)
                    .padding(.bottom, 20)
                    .onTapGesture {
                        // MARK: - Store more about you
                        Onboarding.storeMoreAboutYou(job: job, workLocation: workLocation, relationStatus: relationStatus, interestedInto: interestedInto)
                        appController.path.append(.hobbies)
                    }
            }
        }
        .padding(.horizontal, 32)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    isFocused = false // Dismiss keyboard
                }
            }
        }
        .background(Colors.kF5F5F5.edgesIgnoringSafeArea(.all))
        .navigationBarBackButtonHidden()
        
    }
}

#Preview {
    MoreAboutYouView()
}

struct RoundedButtonView: View {
    
    var title: String
    var isSelected: Bool
    var action: () -> Void
    
    var body: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(isSelected ? Colors.primaryDark : Color.white)
            .frame(height: 36)
            .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 4)
            .overlay {
                Text(title)
                    .foregroundStyle(isSelected ? Color.white : Colors.k6F6F73)
                    .font(Font.LeagueSpartan(size: 14))
            }
            .onTapGesture {
                action()
            }
    }
    
}
