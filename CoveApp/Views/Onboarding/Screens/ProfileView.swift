//
//  ProfileView.swift
//  Cove
//
//  Created by Nesib Muhedin


import SwiftUI
import CoreLocation

// MARK: - Profile Header Component
struct ProfileText: View {
    let text: String
    let isPlaceholder: Bool
    
    var body: some View {
        Text(text.lowercased())
            .font(.LibreBodoni(size: 15))
            .foregroundColor(isPlaceholder ? Colors.k6F6F73 : Colors.primaryDark)
    }
}

struct ProfileHeader: View {
    let name: String
    let workLocation: String
    let gender: String
    let relationStatus: String
    let job: String
    let profileImage: UIImage?
    let age: Int?
    let address: String
    
    var body: some View {
        VStack(spacing: 10) {
            if let image = profileImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: 200, maxHeight: 200)
                    .clipShape(Circle())
            } else {
                Images.profilePlaceholder
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: 200, maxHeight: 200)
                    .clipShape(Circle())
            }
            
            Text(name.lowercased())
                .font(.LibreBodoniMedium(size: 35))
                .foregroundColor(Colors.primaryDark)
            
            VStack(alignment: .leading, spacing: 10) {
                ProfileText(
                    text: address.isEmpty ? "add your location" : address,
                    isPlaceholder: address.isEmpty
                ).frame(maxWidth: .infinity, alignment: .center)
                
                HStack() {
                    Text(age.map(String.init) ?? "21")
                        .font(.LibreBodoni(size: 20))
                        .foregroundColor(Colors.primaryDark)
                    
                    Spacer()
                    
                    Image("more-info")
                    
                    ProfileText(
                        text: gender.isEmpty ? "add gender" : gender,
                        isPlaceholder: gender.isEmpty
                    )
                    
                    Spacer()
                    
                    Image("person-fill")
                    
                    ProfileText(
                        text: relationStatus.isEmpty ? "add status" : relationStatus,
                        isPlaceholder: relationStatus.isEmpty
                    )
                }.padding(.horizontal, 5)
                
                HStack() {
                    Image(systemName: "briefcase")
                        .foregroundStyle(Colors.k6B6B6B)
                    
                    if job.isEmpty || workLocation.isEmpty {
                        ProfileText(text: "add your work", isPlaceholder: true)
                    } else {
                        ProfileText(text: "\(job) @ \(workLocation)", isPlaceholder: false)
                    }
                }
            }
        }
    }
}

// MARK: - Bio Component
struct BioSection: View {
    let bio: String
    
    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            HStack {
                Text(bio.isEmpty ? "add your bio" : bio.lowercased())
                    .font(.LeagueSpartan(size: 14))
                    .foregroundStyle(bio.isEmpty ? Colors.k6F6F73 : Colors.k6F6F73)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, minHeight: 50, maxHeight: .infinity, alignment: .leading)
                    .padding()
            }
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
            )
        }
        .padding()
    }
}

// MARK: - Interests Component
struct InterestsSection: View {
    let interests: [String]
    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("past times")
                .font(.LibreBodoni(size: 18))
                .foregroundColor(Colors.primaryDark)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if interests.isEmpty {
                ZStack {
                    Image("buttonWhite")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                    
                    Text("whoops! add your passtimes!")
                        .font(.LeagueSpartan(size: 14))
                        .foregroundColor(Colors.k6F6F73)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 5)
                }
            } else {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(interests, id: \.self) { hobby in
                        ZStack {
                            Image("buttonWhite")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                            
                            Text(hobby.lowercased())
                                .font(.LeagueSpartan(size: 14))
                                .foregroundColor(Colors.k6F6F73)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .multilineTextAlignment(.center)
                                .padding(.bottom, 5)
                        }
                    }
                }
            }
        }
        .padding()
    }
}

// MARK: - Extra Photo Component
struct ExtraPhotoView: View {
    let image: UIImage?
    
    var body: some View {
        if let image = image {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: AppConstants.SystemSize.width*0.8)
        } else {
            Images.profileActivity1
                .resizable()
                .scaledToFill()
                .frame(maxWidth: AppConstants.SystemSize.width*0.8)
        }
    }
}

// MARK: - Location Helper
func getLocationName(latitude: Double, longitude: Double) async -> String {
    let geocoder = CLGeocoder()
    let location = CLLocation(latitude: latitude, longitude: longitude)
    
    do {
        let placemarks = try await geocoder.reverseGeocodeLocation(location)
        if let placemark = placemarks.first {
            let city = placemark.locality ?? ""
            let state = placemark.administrativeArea ?? ""
            return "\(city), \(state)"
        }
    } catch {
        print("Geocoding error: \(error.localizedDescription)")
    }
    return ""
}

// MARK: - Main Profile View
struct ProfileView: View {
    @EnvironmentObject var appController: AppController
    @State private var isEditing = false
    @State private var address: String = ""
    
    // State variables for profile data
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
    @State private var birthdate: String? = UserDefaults.standard.string(forKey: "user_birthdate")
    @State private var profileImage: UIImage? = {
        if let imageData = UserDefaults.standard.data(forKey: "user_profile_image") {
            return UIImage(data: imageData)
        }
        return nil
    }()
    @State private var extraImages: [UIImage?] = {
        var images: [UIImage?] = []
        for i in 0...1 {
            if let imageData = UserDefaults.standard.data(forKey: "user_extra_image_\(i)") {
                images.append(UIImage(data: imageData))
            } else {
                images.append(nil)
            }
        }
        return images
    }()
    
    private var age: Int? {
        guard let birthdateString = birthdate else { return nil }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        guard let birthdate = dateFormatter.date(from: birthdateString) else { return nil }
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: birthdate, to: Date())
        return ageComponents.year
    }
    
    var body: some View {
        ZStack {
            Colors.faf8f4
                .ignoresSafeArea()
            
            VStack {
                HStack(alignment: .top) {
//                    Button {
//                        appController.path.removeLast()
//                    } label: {
//                        Images.backArrow
//                    }
                    
                    Spacer()
                    
                    Text("cove")
                        .font(.LibreBodoni(size: 70))
                        .foregroundColor(Colors.primaryDark)
                        .frame(maxHeight: 20)
                    
                    Spacer()
                    
                    Button {
                        isEditing.toggle()
                        // TODO: REMOVE BEFORE PUSHING
                        appController.path.append(.exploreFriends)
                    } label: {
                        Image(systemName: "pencil")
                            .foregroundColor(Colors.primaryDark)
                            .font(.system(size: 20))
                    }
                }
                .padding(.vertical, 20)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 20) {
                        ProfileHeader(
                            name: name,
                            workLocation: workLocation,
                            gender: gender,
                            relationStatus: relationStatus,
                            job: job,
                            profileImage: profileImage,
                            age: age,
                            address: address
                        ).frame(maxWidth: 270)
                        
                        ExtraPhotoView(image: extraImages[0])
                        
                        BioSection(bio: bio)
                        
                        ExtraPhotoView(image: extraImages[1])
                        
                        InterestsSection(interests: interests)
                    }
                    .padding(.vertical, 20)
                }
            }
            .padding(.horizontal, 20)
        }
        .navigationBarBackButtonHidden()
        .task {
            if latitude != 0 && longitude != 0 {
                address = await getLocationName(latitude: latitude, longitude: longitude)
            }
        }
    }
}

#Preview {
    ProfileView()
}
