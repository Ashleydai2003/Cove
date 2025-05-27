//
//  ProfileView.swift
//  Cove
//

import SwiftUI

struct ProfileView: View {
    // MARK: - Properties
    
    /// App controller for managing navigation and app state
    @EnvironmentObject var appController: AppController
    
    /// State variables for profile data
    @State private var name: String = UserDefaults.standard.string(forKey: "user_name") ?? ""
    @State private var bio: String = UserDefaults.standard.string(forKey: "user_bio") ?? ""
    @State private var lookingInto: String = UserDefaults.standard.string(forKey: "user_sexuality") ?? ""
    @State private var interests: [String] = UserDefaults.standard.stringArray(forKey: "user_interests") ?? []
    @State private var relationStatus: String = UserDefaults.standard.string(forKey: "user_relation_status") ?? ""
    @State private var job: String = UserDefaults.standard.string(forKey: "user_job") ?? ""
    @State private var workLocation: String = UserDefaults.standard.string(forKey: "user_work_location") ?? ""
    @State private var almaMater: String = UserDefaults.standard.string(forKey: "user_alma_mater") ?? ""
    @State private var latitude: Double = UserDefaults.standard.double(forKey: "user_latitude")
    @State private var longitude: Double = UserDefaults.standard.double(forKey: "user_longitude")
    @State private var gender: String = UserDefaults.standard.string(forKey: "user_gender") ?? ""

    /// Allow to edit user profile or not
    /// When view other user profile, hide edit icons
    @State private var allowProfileEdit: Bool = true
    
    /// Grid layout configuration for hobby buttons
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        ZStack {
            Colors.faf8f4
                .ignoresSafeArea()
            
            VStack {
                HStack(alignment: .top) {
                    Button {
                        appController.path.removeLast()
                    } label: {
                        Images.backArrow
                    }

                    Spacer()
                    
                    Text("cove")
                        .font(.LibreBodoni(size: 70))
                        .foregroundColor(Colors.primaryDark)
                        .frame(height: 20)
                        .padding(.trailing, 16)
                    
                    Spacer()
                }
                .padding(.top, 10)
                
                Spacer().frame(height: 20)
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 10) {
                        ZStack(alignment: .bottomTrailing) {
                            Images.profilePlaceholder
                                .resizable()
                                .scaledToFill()
                                .frame(width: 200, height: 200)
                                .clipShape(Circle())
                            
                            if allowProfileEdit {
                                Button {
                                    //TODO: Update profile photo action
                                } label: {
                                    Images.pencilEdit
                                        .resizable()
                                        .frame(width: 24, height: 24)
                                        .background(Color.white)
                                }
                            }
                        }
                        
                        Text(name)
                            .font(.LibreBodoniMedium(size: 35))
                            .foregroundColor(Colors.primaryDark)
                        
                        VStack(alignment: .leading) {
                            HStack(spacing: 10) {
                                Image("location-pin")
                                // TODO: translate coordinates to location
                                Text("\(workLocation)")
                                    .font(.LibreBodoniBold(size: 14))
                                    .foregroundColor(Colors.primaryDark)
                            }
                            
                            HStack(spacing: 10) {
                                Text("21") // TODO: Calculate age from birthdate
                                    .font(.LibreBodoniBold(size: 20))
                                    .foregroundColor(Colors.primaryDark)
                                
                                Image("more-info")
                                
                                Text(gender) // TODO: Get from profile
                                    .font(.LibreBodoniBold(size: 14))
                                    .foregroundColor(Colors.primaryDark)
                                
                                Image("person-fill")
                                
                                Text(relationStatus)
                                    .font(.LibreBodoniBold(size: 14))
                                    .foregroundColor(Colors.primaryDark)
                            }
                            
                            HStack(spacing: 10) {
                                Image(systemName: "briefcase")
                                    .foregroundStyle(Colors.k6B6B6B)
                                
                                Text("\(job) @ \(workLocation)")
                                    .font(.LibreBodoniBold(size: 14))
                                    .foregroundColor(Colors.primaryDark)
                            }
                        }
                    }
                    
                    VStack(alignment: .center, spacing: 16) {
                        HStack(alignment: .bottom, spacing: 5) {
                            Images.profileActivity1
                            
                            if allowProfileEdit {
                                Button {
                                    //TODO: Edit button action
                                } label: {
                                    Images.pencilEdit
                                        .resizable()
                                        .frame(width: 24, height: 24)
                                        .background(Color.white)
                                }
                            }
                        }
                        
                        HStack {
                            TextEditor(text: $bio)
                                .scrollContentBackground(.hidden)
                                .font(.LeagueSpartan(size: 14))
                                .foregroundStyle(Colors.k6F6F73)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, minHeight: 50, maxHeight: .infinity, alignment: .leading)
                                .disabled(!allowProfileEdit)
                                .padding()
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                        )
                    }
                    .padding()
                    
                    HStack(alignment: .bottom, spacing: 5) {
                        Images.profileActivity2
                            .resizable()
                            .scaledToFill()
                            .frame(width: AppConstants.SystemSize.width*0.8)
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        
                        Text("past times")
                            .font(.LibreBodoniBold(size: 18))
                            .foregroundColor(Colors.primaryDark)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        HStack(alignment: .center, spacing: 16) {
                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(interests, id: \.self) { hobby in
                                    Button(action: {
                                        
                                    }) {
                                        ZStack {
                                            Image("buttonWhite")
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                            
                                            Text(hobby)
                                                .font(.LeagueSpartan(size: 14))
                                                .foregroundColor(Colors.k6F6F73)
                                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                                .multilineTextAlignment(.center)
                                                .padding(.bottom, 5)
                                        }
                                    }
                                }
                            }
                            
                            if allowProfileEdit {
                                Button {
                                    //TODO: Edit button action
                                } label: {
                                    Images.pencilEdit
                                        .resizable()
                                        .frame(width: 24, height: 24)
                                        .background(Color.white)
                                }
                            }
                        }
                        
                        Text("looking to...")
                            .font(.LibreBodoniBold(size: 18))
                            .foregroundColor(Colors.primaryDark)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        VStack {
                            Text(lookingInto)
                                .font(.LeagueSpartan(size: 14))
                                .foregroundStyle(Colors.primaryDark)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color.white)
                        )
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                    }
                    .padding()
                }
            }
            .padding(.horizontal, 20)
        }
        .navigationBarBackButtonHidden()  // Hide default back button to prevent accidental navigation
    }
    
}

#Preview {
    ProfileView()
}
