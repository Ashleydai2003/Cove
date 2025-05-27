import Foundation

struct Profile: Decodable {
    let name: String
    let phone: String
    let onboarding: Bool
    let age: Int?
    let birthdate: Date?
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
    
    struct Photo: Decodable {
        let id: String
        let url: URL
        let isProfilePic: Bool
    }
}

struct ProfileResponse: Decodable {
    let profile: Profile
} 