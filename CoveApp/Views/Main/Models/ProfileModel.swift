import SwiftUI
import Foundation
import CoreLocation
import Kingfisher

/**
 * Photo model for user profile images
 */
struct ProfilePhoto: Decodable {
    let id: String
    let url: URL
    let isProfilePic: Bool
}

/**
 * Stats model for user profile statistics
 */
struct ProfileStats: Decodable {
    let friendCount: Int
    let requestCount: Int
    let coveCount: Int
}

/**
 * Response structure for profile API calls
 */
struct ProfileResponse: Decodable {
    let profile: ProfileData
}

/**
 * Profile data structure from API response
 */
struct ProfileData: Decodable {
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
    let photos: [ProfilePhoto]
    let stats: ProfileStats?
}

/**
 * ProfileModel manages user profile data and provides methods for fetching, updating, and caching profile information.
 * This class serves as the central data store for user profile information used throughout the app.
 */
class ProfileModel: ObservableObject {
    // MARK: - Published Properties (Used for both onboarding and profile data)
    @Published var name: String = ""
    @Published var phone: String = ""
    @Published var onboarding: Bool = false
    @Published var id: String = ""
    @Published var userId: String = ""
    @Published var age: Int?
    @Published var birthdate: String?
    @Published var interests: [String] = []
    @Published var latitude: Double?
    @Published var longitude: Double?
    @Published var almaMater: String?
    @Published var job: String = ""
    @Published var workLocation: String = ""
    @Published var relationStatus: String = ""
    @Published var sexuality: String = ""
    @Published var bio: String = ""
    @Published var gender: String = ""
    @Published var photos: [ProfilePhoto] = []
    @Published var stats: ProfileStats?
    @Published var address: String = ""
    
    // MARK: - Static Images (Loaded once, used everywhere)
    @Published var profileUIImage: UIImage?
    @Published var extraUIImages: [UIImage?] = [nil, nil]
    
    // MARK: - Photo ID Storage
    @Published var profilePhotoId: String?
    @Published var extraPhotoIds: [String?] = [nil, nil]
    
    // MARK: - Onboarding Temporary Storage (only what's not in main properties)
    @Published var pendingFriendRequests: [String] = []
    @Published var adminCove: String?
    
    // MARK: - Loading States
    @Published var isLoading: Bool = false
    @Published var lastFetchTime: Date?
    
    // MARK: - Cancellation Support
    private var currentDataTask: URLSessionDataTask?
    private var isCancelled: Bool = false
    
    // MARK: - Computed Properties
    
    /**
     * Calculates the user's age based on their birthdate.
     * 
     * - Returns: The calculated age in years, or nil if birthdate is not available or invalid
     */
    var calculatedAge: Int? {
        guard let birthdateString = birthdate else { return nil }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        guard let birthdate = dateFormatter.date(from: birthdateString) else { return nil }
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: birthdate, to: Date())
        return ageComponents.year
    }
    
    /**
     * Converts the birthdate string to a Date object and vice versa.
     * 
     * - Returns: The birthdate as a Date object, or nil if not available
     * - Parameter newValue: The new Date value to set as birthdate
     */
    var birthdateAsDate: Date? {
        get {
            guard let birthdateString = birthdate else { return nil }
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            return dateFormatter.date(from: birthdateString)
        }
        set {
            if let newDate = newValue {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                birthdate = dateFormatter.string(from: newDate)
            } else {
                birthdate = nil
            }
        }
    }
    
    /**
     * Checks if the user has completed the onboarding process.
     * 
     * - Returns: True if all required onboarding fields are filled, false otherwise
     */
    var isOnboardingComplete: Bool {
        return !name.isEmpty && 
               birthdate != nil && 
               latitude != nil && 
               longitude != nil
    }
    
    /**
     * Returns the profile photo URL if available
     */
    var profileImageURL: URL? {
        return photos.first { $0.isProfilePic }?.url
    }
    
    /**
     * Returns the extra photo URLs (up to 2)
     */
    var extraImageURLs: [URL] {
        return photos.filter { !$0.isProfilePic }.prefix(2).map { $0.url }
    }
    
    // MARK: - Initialization
    
    /**
     * Initializes a new ProfileModel instance.
     * Data will be fetched from the backend rather than loaded from UserDefaults.
     */
    init() {
        // No longer loading from UserDefaults - data will be fetched from backend
    }
    
    // MARK: - Data Management
    
    /**
     * Updates the ProfileModel with data from a ProfileData object.
     * This method is called after fetching profile data from the backend.
     * 
     * - Parameter profileData: The ProfileData object containing user data
     */
    func updateFromProfileData(_ profileData: ProfileData) {
        name = profileData.name
        phone = profileData.phone
        onboarding = profileData.onboarding
        id = profileData.id
        userId = profileData.userId
        age = profileData.age
        birthdate = profileData.birthdate
        interests = profileData.interests
        latitude = profileData.latitude
        longitude = profileData.longitude
        almaMater = profileData.almaMater
        job = profileData.job ?? ""
        workLocation = profileData.workLocation ?? ""
        relationStatus = profileData.relationStatus ?? ""
        sexuality = profileData.sexuality ?? ""
        bio = profileData.bio ?? ""
        gender = profileData.gender ?? ""
        photos = profileData.photos
        stats = profileData.stats
        
        // Debug logging for photos
        print("📸 Profile photos received: \(photos.count) total")
        print("📸 Photos array: \(photos)")
        
        if photos.isEmpty {
            print("⚠️ WARNING: No photos found in profile!")
        } else {
            for (index, photo) in photos.enumerated() {
                print("📸 Photo \(index): id=\(photo.id), isProfilePic=\(photo.isProfilePic), url=\(photo.url)")
            }
        }
        
        // Store photo IDs
        profilePhotoId = profileData.photos.first { $0.isProfilePic }?.id
        let extraPhotos = profileData.photos.filter { !$0.isProfilePic }
        extraPhotoIds = [nil, nil]
        for (index, photo) in extraPhotos.enumerated() {
            if index < 2 {
                extraPhotoIds[index] = photo.id
            }
        }
        
        print("📸 Photo categorization: profilePhotoId=\(profilePhotoId ?? "nil"), extraPhotoIds=\(extraPhotoIds)")
        print("📸 Profile image URL: \(profileImageURL?.absoluteString ?? "nil")")
        print("📸 Extra image URLs: \(extraImageURLs.map { $0.absoluteString })")
        
        // Load all images automatically when profile data is updated
        loadAllImages()
        
        // Update fetch time
        lastFetchTime = Date()
    }
    
    /**
     * Cancels any ongoing network requests.
     * This should be called when views are dismissed to prevent loading states from persisting.
     */
    func cancelAllRequests() {
        print("🛑 cancelAllRequests called - cancelling all tasks")
        isCancelled = true
        
        // Cancel current data task
        currentDataTask?.cancel()
        currentDataTask = nil
        
        // Reset loading states if cancelled
        if isCancelled {
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
    }
    
    /**
     * Resets the cancellation flag when starting new requests.
     */
    private func resetCancellationFlag() {
        isCancelled = false
    }
    
    // MARK: - Backend Integration
    
    /**
     * Fetches the user's profile data from the backend.
     * 
     * - Parameter completion: A closure called with the result of the fetch operation
     *   - Success: Returns the ProfileData object
     *   - Failure: Returns a NetworkError
     */
    func fetchProfile(completion: @escaping (Result<ProfileData, NetworkError>) -> Void) {
        guard !isLoading else {
            completion(.failure(.networkError(NSError(domain: "ProfileModel", code: 429, userInfo: [NSLocalizedDescriptionKey: "Request already in progress"]))))
            return
        }
        
        resetCancellationFlag()
        isLoading = true
        
        NetworkManager.shared.get(endpoint: "/profile") { [weak self] (result: Result<ProfileResponse, NetworkError>) in
            guard let self = self else { return }
            
            // Check if request was cancelled
            guard !self.isCancelled else {
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                return
            }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let response):
                    self.updateFromProfileData(response.profile)
                    completion(.success(response.profile))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    /**
     * Updates the user's profile on the backend with the provided fields.
     * This method is used for both onboarding and profile editing.
     * 
     * - Parameters:
     *   - name: User's display name
     *   - birthdate: User's birthdate in "yyyy-MM-dd" format
     *   - interests: Array of user's interests
     *   - bio: User's biography
     *   - latitude: User's location latitude
     *   - longitude: User's location longitude
     *   - almaMater: User's alma mater
     *   - job: User's job title
     *   - workLocation: User's work location
     *   - relationStatus: User's relationship status
     *   - sexuality: User's sexuality
     *   - gender: User's gender
     *   - isOnboarding: If true, uses onboarding endpoint; otherwise uses edit-profile endpoint
     *   - completion: A closure called with the result of the update operation
     *     - Success: Returns void
     *     - Failure: Returns a NetworkError
     */
    func updateProfile(
        name: String? = nil,
        birthdate: String? = nil,
        interests: [String]? = nil,
        bio: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        almaMater: String? = nil,
        job: String? = nil,
        workLocation: String? = nil,
        relationStatus: String? = nil,
        sexuality: String? = nil,
        gender: String? = nil,
        isOnboarding: Bool = false,
        completion: @escaping (Result<Void, NetworkError>) -> Void
    ) {
        // Build parameters dictionary with only changed values
        var parameters: [String: Any] = [:]
        
        // Helper function to add parameter if changed
        func addIfChanged<T: Equatable>(_ key: String, newValue: T?, currentValue: T?) {
            if let newValue = newValue, newValue != currentValue {
                parameters[key] = newValue
            }
        }
        
        // Check each field for changes
        addIfChanged("name", newValue: name, currentValue: self.name)
        addIfChanged("birthdate", newValue: birthdate, currentValue: self.birthdate)
        addIfChanged("interests", newValue: interests, currentValue: self.interests)
        addIfChanged("bio", newValue: bio, currentValue: self.bio)
        addIfChanged("latitude", newValue: latitude, currentValue: self.latitude)
        addIfChanged("longitude", newValue: longitude, currentValue: self.longitude)
        addIfChanged("almaMater", newValue: almaMater, currentValue: self.almaMater)
        addIfChanged("job", newValue: job, currentValue: self.job)
        addIfChanged("workLocation", newValue: workLocation, currentValue: self.workLocation)
        addIfChanged("relationStatus", newValue: relationStatus, currentValue: self.relationStatus)
        addIfChanged("sexuality", newValue: sexuality, currentValue: self.sexuality)
        addIfChanged("gender", newValue: gender, currentValue: self.gender)
        
        // Use different endpoints for onboarding vs profile editing
        let endpoint = isOnboarding ? "/onboard" : "/edit-profile"
        
        NetworkManager.shared.post(endpoint: endpoint, parameters: parameters) { [weak self] (result: Result<ProfileUpdateResponse, NetworkError>) in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success(_):
                    // Update all local @Published variables after successful backend call
                    // This ensures the UI updates immediately with the new data
                    if let name = name { self.name = name }
                    if let birthdate = birthdate { self.birthdate = birthdate }
                    if let interests = interests { self.interests = interests }
                    if let bio = bio { self.bio = bio }
                    if let latitude = latitude { self.latitude = latitude }
                    if let longitude = longitude { self.longitude = longitude }
                    if let almaMater = almaMater { self.almaMater = almaMater }
                    if let job = job { self.job = job }
                    if let workLocation = workLocation { self.workLocation = workLocation }
                    if let relationStatus = relationStatus { self.relationStatus = relationStatus }
                    if let sexuality = sexuality { self.sexuality = sexuality }
                    if let gender = gender { self.gender = gender }
                    
                    // Update address if location changed
                    if parameters["latitude"] != nil || parameters["longitude"] != nil {
                        Task {
                            await self.updateAddress()
                        }
                    }
                    
                    completion(.success(()))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    // MARK: - Location Helper
    
    /**
     * Updates the address field by reverse geocoding the current latitude and longitude coordinates.
     * This method is called automatically when location coordinates are updated.
     */
    func updateAddress() async {
        guard let lat = latitude, let lon = longitude, lat != 0, lon != 0 else { return }
        
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: lat, longitude: lon)
        
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            if let placemark = placemarks.first {
                let city = placemark.locality ?? ""
                let state = placemark.administrativeArea ?? ""
                address = "\(city), \(state)"
            }
        } catch {
            print("Geocoding error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Clear Data
    
    /**
     * Clears all profile data and resets the model to its initial state.
     * This method is typically called when the user logs out.
     */
    func clearData() {
        name = ""
        phone = ""
        onboarding = false
        id = ""
        userId = ""
        age = nil
        birthdate = nil
        interests = []
        latitude = nil
        longitude = nil
        almaMater = nil
        job = ""
        workLocation = ""
        relationStatus = ""
        sexuality = ""
        bio = ""
        gender = ""
        photos = []
        stats = nil
        address = ""
        lastFetchTime = nil
        profilePhotoId = nil
        extraPhotoIds = [nil, nil]
        
        // Clear loaded images
        clearImages()
    }
    
    /**
     * Loads all profile images using Kingfisher and stores them as static UIImages.
     * This method should be called after profile data is fetched.
     */
    func loadAllImages() {
        // Load profile image
        if let profileURL = profileImageURL {
            KingfisherManager.shared.retrieveImage(with: profileURL) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let imageResult):
                        self.profileUIImage = imageResult.image
                        print("✅ Profile image loaded and stored")
                    case .failure(let error):
                        print("❌ Failed to load profile image: \(error)")
                        self.profileUIImage = nil
                    }
                }
            }
        }
        
        // Load extra images
        for (index, url) in extraImageURLs.enumerated() {
            KingfisherManager.shared.retrieveImage(with: url) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let imageResult):
                        if index < self.extraUIImages.count {
                            self.extraUIImages[index] = imageResult.image
                        }
                        print("✅ Extra image \(index) loaded and stored")
                    case .failure(let error):
                        print("❌ Failed to load extra image \(index): \(error)")
                        if index < self.extraUIImages.count {
                            self.extraUIImages[index] = nil
                        }
                    }
                }
            }
        }
    }
    
    /**
     * Clears all loaded images from memory.
     */
    func clearImages() {
        profileUIImage = nil
        extraUIImages = [nil, nil]
    }
}

// MARK: - Supporting Types

/**
 * Response structure for profile update operations.
 */
struct EditProfileResponse: Decodable {
    let message: String
}

/**
 * Response structure for profile update operations.
 */
struct ProfileUpdateResponse: Decodable {
    let message: String
}

/**
 * Response structure for friend request operations.
 */
struct FriendRequestResponse: Decodable {
    let message: String
    let requestIds: [String]?
}

// MARK: - Array Extension for Safe Access
extension Array {
    /**
     * Safely accesses an array element at the specified index.
     * Returns nil if the index is out of bounds.
     * 
     * - Parameter index: The index to access
     * - Returns: The element at the index, or nil if out of bounds
     */
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
} 