// Created by Nesib Muhedin
import Foundation

// TODO: this is probably not needed anymore
struct Profile: Decodable {
    let name: String
    let phone: String
    let onboarding: Bool
    let id: String
    let userId: String
    let age: Int?
    let birthdate: String?
    let interests: [String]
    let latitude: Double?
    let longitude: Double?
    let almaMater: String?
    let job: String?
    let workLocation: String?
    let relationStatus: String?
    let sexuality: String?
    let bio: String?
    let gender: String?
    let photos: [Photo]
    let stats: Stats?
    
    struct Photo: Decodable {
        let id: String
        let url: URL
        let isProfilePic: Bool
    }
    
    struct Stats: Decodable {
        let friendCount: Int
        let requestCount: Int
        let coveCount: Int
    }
    
    func calculateAge() -> Int? {
        guard let birthdateString = birthdate else { return nil }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        guard let birthdate = dateFormatter.date(from: birthdateString) else { return nil }
        
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: birthdate, to: Date())
        return ageComponents.year
    }
}

struct ProfileResponse: Decodable {
    let profile: Profile
} 
