import SwiftUI
import Foundation
import CoreLocation

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
    @Published var job: String?
    @Published var workLocation: String?
    @Published var relationStatus: String?
    @Published var sexuality: String?
    @Published var bio: String?
    @Published var gender: String?
    @Published var photos: [Profile.Photo] = []
    @Published var stats: Profile.Stats?
    @Published var profileImage: UIImage?
    @Published var extraImages: [UIImage?] = [nil, nil]
    @Published var address: String = ""
    
    // MARK: - Photo ID Storage
    @Published var profilePhotoId: String?
    @Published var extraPhotoIds: [String?] = [nil, nil]
    
    // MARK: - Onboarding Temporary Storage (only what's not in main properties)
    @Published var pendingFriendRequests: [String] = []
    @Published var adminCove: String?
    
    // MARK: - Loading States
    @Published var isLoading: Bool = false
    @Published var imagesLoading: Bool = false
    @Published var lastFetchTime: Date?
    
    // MARK: - Cancellation Support
    private var currentDataTask: URLSessionDataTask?
    private var imageLoadingTasks: [URLSessionDataTask] = []
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
     * Updates the ProfileModel with data from a Profile object.
     * This method is called after fetching profile data from the backend.
     * 
     * - Parameter profile: The Profile object containing user data
     */
    func updateFromProfile(_ profile: Profile) {
        name = profile.name
        phone = profile.phone
        onboarding = profile.onboarding
        id = profile.id
        userId = profile.userId
        age = profile.age
        birthdate = profile.birthdate
        interests = profile.interests
        latitude = profile.latitude
        longitude = profile.longitude
        almaMater = profile.almaMater
        job = profile.job
        workLocation = profile.workLocation
        relationStatus = profile.relationStatus
        sexuality = profile.sexuality
        bio = profile.bio
        gender = profile.gender
        photos = profile.photos
        stats = profile.stats
        
        // Store photo IDs
        profilePhotoId = profile.photos.first { $0.isProfilePic }?.id
        let extraPhotos = profile.photos.filter { !$0.isProfilePic }
        extraPhotoIds = [nil, nil]
        for (index, photo) in extraPhotos.enumerated() {
            if index < 2 {
                extraPhotoIds[index] = photo.id
            }
        }
        
        // Load images from photos with completion handler
        loadImagesFromPhotos {
            print("✅ Profile data and images fully loaded")
        }
        
        // Update fetch time
        lastFetchTime = Date()
    }
    
    /**
     * Loads profile images from the photos array by downloading them from URLs.
     * Sets the profileImage and extraImages based on the downloaded data.
     * 
     * - Parameter completion: Optional completion handler called when all images are loaded
     */
    func loadImagesFromPhotos(completion: (() -> Void)? = nil) {
        guard !photos.isEmpty else {
            completion?()
            return
        }
        
        // Clear any existing image loading tasks
        imageLoadingTasks.forEach { $0.cancel() }
        imageLoadingTasks.removeAll()
        
        imagesLoading = true
        let group = DispatchGroup()
        var loadedCount = 0
        let totalImages = min(photos.count, 3) // Profile + up to 2 extra images
        
        for (index, photo) in photos.enumerated() {
            if index >= 3 { break } // Only load first 3 images
            
            group.enter()
            let task = URLSession.shared.dataTask(with: photo.url) { [weak self] data, response, error in
                defer { group.leave() }
                
                guard let self = self else { return }
                
                // Check if request was cancelled
                guard !self.isCancelled else { return }
                
                guard let imageData = data else {
                    print("❌ Failed to load image for photo \(photo.id): \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                DispatchQueue.main.async {
                    // Check again if cancelled on main thread
                    guard !self.isCancelled else { return }
                    
                    if photo.isProfilePic {
                        self.profileImage = UIImage(data: imageData)
                        print("✅ Profile image loaded successfully")
                    } else if index < 2 { // Only store up to 2 additional photos
                        self.extraImages[index] = UIImage(data: imageData)
                        print("✅ Extra image \(index) loaded successfully")
                    }
                    
                    loadedCount += 1
                    print("📸 Loaded \(loadedCount)/\(totalImages) images")
                }
            }
            
            // Store the task for potential cancellation
            imageLoadingTasks.append(task)
            task.resume()
        }
        
        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            
            // Check if request was cancelled
            guard !self.isCancelled else { return }
            
            self.imagesLoading = false
            print("✅ All images loaded: \(loadedCount)/\(totalImages)")
            completion?()
        }
    }
    
    /**
     * Cancels any ongoing network requests and image loading tasks.
     * This should be called when views are dismissed to prevent loading states from persisting.
     */
    func cancelAllRequests() {
        isCancelled = true
        
        // Cancel current data task
        currentDataTask?.cancel()
        currentDataTask = nil
        
        // Cancel all image loading tasks
        imageLoadingTasks.forEach { $0.cancel() }
        imageLoadingTasks.removeAll()
        
        // Reset loading states if cancelled
        if isCancelled {
            DispatchQueue.main.async {
                self.isLoading = false
                self.imagesLoading = false
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
     *   - Success: Returns the Profile object
     *   - Failure: Returns a NetworkError
     */
    func fetchProfile(completion: @escaping (Result<Profile, NetworkError>) -> Void) {
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
                    self.updateFromProfile(response.profile)
                    completion(.success(response.profile))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    /**
     * Refreshes profile data if needed, using cached data if it's recent enough.
     * 
     * - Parameters:
     *   - forceRefresh: If true, ignores cache and fetches fresh data
     *   - completion: A closure called with the result of the refresh operation
     *     - Success: Returns the Profile object (cached or fresh)
     *     - Failure: Returns a NetworkError
     */
    func refreshProfileIfNeeded(forceRefresh: Bool = false, completion: @escaping (Result<Profile, NetworkError>) -> Void) {
        // If we have recent data and not forcing refresh, return cached data
        if !forceRefresh, 
           let lastFetch = lastFetchTime,
           Date().timeIntervalSince(lastFetch) < 300 { // 5 minutes cache
            // Return cached data if available
            if !name.isEmpty {
                let cachedProfile = Profile(
                    name: name,
                    phone: phone,
                    onboarding: onboarding,
                    id: id,
                    userId: userId,
                    age: age,
                    birthdate: birthdate,
                    interests: interests,
                    latitude: latitude,
                    longitude: longitude,
                    almaMater: almaMater,
                    job: job,
                    workLocation: workLocation,
                    relationStatus: relationStatus,
                    sexuality: sexuality,
                    bio: bio,
                    gender: gender,
                    photos: photos,
                    stats: stats
                )
                completion(.success(cachedProfile))
                return
            }
        }
        
        // Fetch fresh data from backend
        fetchProfile(completion: completion)
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
     *   - profileImage: New profile image (nil if unchanged)
     *   - extraImages: Array of new extra images (nil elements if unchanged)
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
        profileImage: UIImage? = nil,
        extraImages: [UIImage?]? = nil,
        isOnboarding: Bool = false,
        completion: @escaping (Result<Void, NetworkError>) -> Void
    ) {
        // Check if any fields have actually changed
        let hasNameChanged = name != nil && name != self.name
        let hasBirthdateChanged = birthdate != nil && birthdate != self.birthdate
        let hasInterestsChanged = interests != nil && interests != self.interests
        let hasBioChanged = bio != nil && bio != self.bio
        let hasLatitudeChanged = latitude != nil && latitude != self.latitude
        let hasLongitudeChanged = longitude != nil && longitude != self.longitude
        let hasAlmaMaterChanged = almaMater != nil && almaMater != self.almaMater
        let hasJobChanged = job != nil && job != self.job
        let hasWorkLocationChanged = workLocation != nil && workLocation != self.workLocation
        let hasRelationStatusChanged = relationStatus != nil && relationStatus != self.relationStatus
        let hasSexualityChanged = sexuality != nil && sexuality != self.sexuality
        let hasGenderChanged = gender != nil && gender != self.gender
        
        let hasProfileImageChanged = profileImage != nil && profileImage != self.profileImage
        let hasExtraImagesChanged = extraImages != nil && extraImages != self.extraImages
        
        // If no fields have changed, return success immediately
        if !hasNameChanged && !hasBirthdateChanged && !hasInterestsChanged && !hasBioChanged &&
           !hasLatitudeChanged && !hasLongitudeChanged && !hasAlmaMaterChanged && !hasJobChanged &&
           !hasWorkLocationChanged && !hasRelationStatusChanged && !hasSexualityChanged && !hasGenderChanged &&
           !hasProfileImageChanged && !hasExtraImagesChanged {
            completion(.success(()))
            return
        }
        
        // First, handle image uploads if any images have changed
        let group = DispatchGroup()
        var uploadError: NetworkError?
        
        // Check and upload profile image if changed
        if hasProfileImageChanged, let newProfileImage = profileImage {
            group.enter()
            guard let imageData = newProfileImage.jpegData(compressionQuality: 0.8) else {
                uploadError = .networkError(NSError(domain: "ProfileModel", code: 400, userInfo: [NSLocalizedDescriptionKey: "Failed to convert profile image to JPEG"]))
                group.leave()
                group.notify(queue: .main) {
                    completion(.failure(uploadError!))
                }
                return
            }
            
            if let existingPhotoId = self.profilePhotoId {
                // Update existing profile image
                UserImage.updateImage(imageData: imageData, photoId: existingPhotoId) { result in
                    switch result {
                    case .success:
                        print("✅ Profile image updated successfully")
                    case .failure(let error):
                        print("❌ Profile image update failed: \(error)")
                        uploadError = .networkError(error)
                    }
                    group.leave()
                }
            } else {
                // Upload new profile image
                UserImage.upload(imageData: imageData, isProfilePic: true) { result in
                    switch result {
                    case .success:
                        print("✅ Profile image uploaded successfully")
                    case .failure(let error):
                        print("❌ Profile image upload failed: \(error)")
                        uploadError = .networkError(error)
                    }
                    group.leave()
                }
            }
        }
        
        // Check and upload extra images if changed
        if hasExtraImagesChanged, let newExtraImages = extraImages {
            for (index, newImage) in newExtraImages.enumerated() {
                if let newImage = newImage, newImage != self.extraImages[safe: index] {
                    group.enter()
                    guard let imageData = newImage.jpegData(compressionQuality: 0.8) else {
                        uploadError = .networkError(NSError(domain: "ProfileModel", code: 400, userInfo: [NSLocalizedDescriptionKey: "Failed to convert extra image to JPEG"]))
                        group.leave()
                        group.notify(queue: .main) {
                            completion(.failure(uploadError!))
                        }
                        return
                    }
                    
                    if let existingPhotoId = self.extraPhotoIds[safe: index], let photoId = existingPhotoId {
                        // Update existing extra image
                        UserImage.updateImage(imageData: imageData, photoId: photoId) { result in
                            switch result {
                            case .success:
                                print("✅ Extra image \(index) updated successfully")
                            case .failure(let error):
                                print("❌ Extra image \(index) update failed: \(error)")
                                uploadError = .networkError(error)
                            }
                            group.leave()
                        }
                    } else {
                        // Upload new extra image
                        UserImage.upload(imageData: imageData, isProfilePic: false) { result in
                            switch result {
                            case .success:
                                print("✅ Extra image \(index) uploaded successfully")
                            case .failure(let error):
                                print("❌ Extra image \(index) upload failed: \(error)")
                                uploadError = .networkError(error)
                            }
                            group.leave()
                        }
                    }
                }
            }
        }
        
        // Wait for all image uploads to complete, then update profile data
        group.notify(queue: .main) {
            // Check if any image uploads failed
            if let error = uploadError {
                completion(.failure(error))
                return
            }
            
            // Build parameters dictionary with only changed values
            var parameters: [String: Any] = [:]
            
            if hasNameChanged, let name = name { parameters["name"] = name }
            if hasBirthdateChanged, let birthdate = birthdate { parameters["birthdate"] = birthdate }
            if hasInterestsChanged, let interests = interests { parameters["hobbies"] = interests }
            if hasBioChanged, let bio = bio { parameters["bio"] = bio }
            if hasLatitudeChanged, let latitude = latitude { parameters["latitude"] = latitude }
            if hasLongitudeChanged, let longitude = longitude { parameters["longitude"] = longitude }
            if hasAlmaMaterChanged, let almaMater = almaMater { parameters["almaMater"] = almaMater }
            if hasJobChanged, let job = job { parameters["job"] = job }
            if hasWorkLocationChanged, let workLocation = workLocation { parameters["workLocation"] = workLocation }
            if hasRelationStatusChanged, let relationStatus = relationStatus { parameters["relationStatus"] = relationStatus }
            if hasSexualityChanged, let sexuality = sexuality { parameters["sexuality"] = sexuality }
            if hasGenderChanged, let gender = gender { parameters["gender"] = gender }
            
            // If no profile data fields have changed and no images were uploaded, return success
            if parameters.isEmpty && !hasProfileImageChanged && !hasExtraImagesChanged {
                completion(.success(()))
                return
            }
            
            // Use different endpoints for onboarding vs profile editing
            let endpoint = isOnboarding ? "/onboard" : "/edit-profile"
            
            NetworkManager.shared.post(endpoint: endpoint, parameters: parameters) { [weak self] (result: Result<ProfileUpdateResponse, NetworkError>) in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    switch result {
                    case .success(_):
                        // Update all local @Published variables after successful backend call
                        // This ensures the UI updates immediately with the new data
                        if hasNameChanged, let name = name { self.name = name }
                        if hasBirthdateChanged, let birthdate = birthdate { self.birthdate = birthdate }
                        if hasInterestsChanged, let interests = interests { self.interests = interests }
                        if hasBioChanged, let bio = bio { self.bio = bio }
                        if hasLatitudeChanged, let latitude = latitude { self.latitude = latitude }
                        if hasLongitudeChanged, let longitude = longitude { self.longitude = longitude }
                        if hasAlmaMaterChanged, let almaMater = almaMater { self.almaMater = almaMater }
                        if hasJobChanged, let job = job { self.job = job }
                        if hasWorkLocationChanged, let workLocation = workLocation { self.workLocation = workLocation }
                        if hasRelationStatusChanged, let relationStatus = relationStatus { self.relationStatus = relationStatus }
                        if hasSexualityChanged, let sexuality = sexuality { self.sexuality = sexuality }
                        if hasGenderChanged, let gender = gender { self.gender = gender }
                        
                        // Update local images if they were uploaded successfully
                        if hasProfileImageChanged, let newProfileImage = profileImage {
                            self.profileImage = newProfileImage
                        }
                        if hasExtraImagesChanged, let newExtraImages = extraImages {
                            for (index, newImage) in newExtraImages.enumerated() {
                                if let newImage = newImage, newImage != self.extraImages[safe: index] {
                                    if index < self.extraImages.count {
                                        self.extraImages[index] = newImage
                                    } else {
                                        self.extraImages.append(newImage)
                                    }
                                }
                            }
                        }
                        
                        // Update address if location changed
                        if hasLatitudeChanged || hasLongitudeChanged {
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
        profileImage = nil
        extraImages = [nil, nil]
        address = ""
        lastFetchTime = nil
        profilePhotoId = nil
        extraPhotoIds = [nil, nil]
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