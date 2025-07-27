import SwiftUI
import Foundation
import CoreLocation
import Kingfisher
import FirebaseAuth

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
    let sharedCoveCount: Int?
    let sharedEventCount: Int?
    let sharedFriendCount: Int?
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
    let verified: Bool?
    let id: String
    let userId: String
    let age: Int?
    let birthdate: String?
    let interests: [String]
    let latitude: Double?
    let longitude: Double?
    let almaMater: String?
    let gradYear: String?
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
@MainActor
class ProfileModel: ObservableObject {
    // MARK: - Published Properties (Used for both onboarding and profile data)
    @Published var name: String = ""
    @Published var phone: String = ""
    @Published var onboarding: Bool = false
    @Published var verified: Bool = false
    @Published var id: String = ""
    @Published var userId: String = ""

    /// Computed property to get the current user ID from Firebase Auth
    var currentUserId: String {
        return Auth.auth().currentUser?.uid ?? userId
    }
    @Published var age: Int?
    @Published var birthdate: String?
    @Published var interests: [String] = []
    @Published var latitude: Double?
    @Published var longitude: Double?
    @Published var almaMater: String?
    @Published var gradYear: String = ""
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
    @Published var isProfileImageLoading: Bool = false

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
        
        // Try ISO8601 parsing first
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var birthdateDate: Date? = isoFormatter.date(from: birthdateString)

        // Fallback to yyyy-MM-dd if needed
        if birthdateDate == nil {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            birthdateDate = dateFormatter.date(from: birthdateString)
        }

        guard let birthdate = birthdateDate else { return nil }

        let calendar = Calendar.current
        let now = Date()
        let ageComponents = calendar.dateComponents([.year], from: birthdate, to: now)
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

        // Only update verified status if it's explicitly provided in the profile response
        // Otherwise preserve the existing value (which should come from login)
        if let verifiedFromProfile = profileData.verified {
            verified = verifiedFromProfile
                    // Profile verified status updated from API
        } else {
        // Preserving existing verified status
        }

        id = profileData.id
        // Use Firebase Auth current user ID for consistency and security
        userId = Auth.auth().currentUser?.uid ?? profileData.userId

        age = profileData.age
        birthdate = profileData.birthdate
        interests = profileData.interests
        latitude = profileData.latitude
        longitude = profileData.longitude
        almaMater = profileData.almaMater
        gradYear = profileData.gradYear ?? ""
        job = profileData.job ?? ""
        workLocation = profileData.workLocation ?? ""
        relationStatus = profileData.relationStatus ?? ""
        sexuality = profileData.sexuality ?? ""
        bio = profileData.bio ?? ""
        gender = profileData.gender ?? ""
        photos = profileData.photos
        stats = profileData.stats

        // Profile photos processed

        // Store photo IDs
        profilePhotoId = profileData.photos.first { $0.isProfilePic }?.id
        let extraPhotos = profileData.photos.filter { !$0.isProfilePic }
        extraPhotoIds = [nil, nil]
        for (index, photo) in extraPhotos.enumerated() {
            if index < 2 {
                extraPhotoIds[index] = photo.id
            }
        }

        // Photo categorization updated

        // Load all images automatically when profile data is updated
        loadAllImages()

        // Update fetch time
        lastFetchTime = Date()

        // Automatically update address if we have location coordinates
        if let lat = latitude, let lon = longitude, lat != 0, lon != 0 {
            Task {
                await updateAddress()
            }
        }
    }

    /**
     * Cancels any ongoing network requests.
     * This should be called when views are dismissed to prevent loading states from persisting.
     */
    func cancelAllRequests() {
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
                    // Debug: Log the profile data to see what's being returned
                    print("🔍 DEBUG: Profile API response - gradYear: \(response.profile.gradYear ?? "nil")")
                    print("🔍 DEBUG: Profile API response - almaMater: \(response.profile.almaMater ?? "nil")")
                    self.updateFromProfileData(response.profile)
                    completion(.success(response.profile))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }

    // MARK: - Refactored Helpers for updateProfile
    private func uploadAllImages(profileImage: UIImage?, extraImages: [UIImage?], completion: @escaping (Result<Void, NetworkError>) -> Void) {
        let imageUploadGroup = DispatchGroup()
        var imageUploadErrors: [NetworkError] = []

        // Upload profile image if changed
        if let newProfileImage = profileImage {
            imageUploadGroup.enter()
            uploadImage(newProfileImage, photoId: profilePhotoId, isProfilePic: true) { result in
                switch result {
                case .success:
                    DispatchQueue.main.async { self.profileUIImage = newProfileImage }
                case .failure(let error):
                    imageUploadErrors.append(error)
                }
                imageUploadGroup.leave()
            }
        }

        // Upload extra images if changed
        for (index, newImage) in extraImages.enumerated() {
            if let newImage = newImage {
                imageUploadGroup.enter()
                let photoId = index < extraPhotoIds.count ? extraPhotoIds[index] : nil
                uploadImage(newImage, photoId: photoId, isProfilePic: false) { result in
                    switch result {
                    case .success:
                        DispatchQueue.main.async {
                            if index < self.extraUIImages.count {
                                self.extraUIImages[index] = newImage
                            }
                        }
                    case .failure(let error):
                        imageUploadErrors.append(error)
                    }
                    imageUploadGroup.leave()
                }
            }
        }

        imageUploadGroup.notify(queue: .main) {
            if !imageUploadErrors.isEmpty {
                completion(.failure(imageUploadErrors.first!))
            } else {
                completion(.success(()))
            }
        }
            }

    private func buildChangedParameters(
        name: String?, birthdate: String?, interests: [String]?, bio: String?, latitude: Double?, longitude: Double?, almaMater: String?, gradYear: String?, job: String?, workLocation: String?, relationStatus: String?, sexuality: String?, gender: String?
    ) -> [String: Any] {
            var parameters: [String: Any] = [:]
            func addIfChanged<T: Equatable>(_ key: String, newValue: T?, currentValue: T?) {
                if let newValue = newValue, newValue != currentValue {
                    parameters[key] = newValue
                }
            }
            addIfChanged("name", newValue: name, currentValue: self.name)
            addIfChanged("birthdate", newValue: birthdate, currentValue: self.birthdate)
            addIfChanged("interests", newValue: interests, currentValue: self.interests)
            addIfChanged("bio", newValue: bio, currentValue: self.bio)
            addIfChanged("latitude", newValue: latitude, currentValue: self.latitude)
            addIfChanged("longitude", newValue: longitude, currentValue: self.longitude)
            addIfChanged("almaMater", newValue: almaMater, currentValue: self.almaMater)
            addIfChanged("gradYear", newValue: gradYear, currentValue: self.gradYear)
            addIfChanged("job", newValue: job, currentValue: self.job)
            addIfChanged("workLocation", newValue: workLocation, currentValue: self.workLocation)
            addIfChanged("relationStatus", newValue: relationStatus, currentValue: self.relationStatus)
            addIfChanged("sexuality", newValue: sexuality, currentValue: self.sexuality)
            addIfChanged("gender", newValue: gender, currentValue: self.gender)
        return parameters
    }

    private func updateLocalState(
        name: String?, birthdate: String?, interests: [String]?, bio: String?, latitude: Double?, longitude: Double?, almaMater: String?, gradYear: String?, job: String?, workLocation: String?, relationStatus: String?, sexuality: String?, gender: String?, parameters: [String: Any]
    ) {
        Log.debug("📱 ProfileModel: updateLocalState called")
        Log.debug("📱 ProfileModel: Updating with values:")
        Log.debug("  - name: \(name ?? "nil")")
        Log.debug("  - interests: \(interests?.description ?? "nil")")
        Log.debug("  - bio: \(bio ?? "nil")")
        Log.debug("  - job: \(job ?? "nil")")
        Log.debug("  - workLocation: \(workLocation ?? "nil")")
        Log.debug("  - relationStatus: \(relationStatus ?? "nil")")
        Log.debug("  - gender: \(gender ?? "nil")")
        
        if let name = name { self.name = name }
        if let birthdate = birthdate { self.birthdate = birthdate }
        if let interests = interests { self.interests = interests }
        if let bio = bio { self.bio = bio }
        if let latitude = latitude { self.latitude = latitude }
        if let longitude = longitude { self.longitude = longitude }
        if let almaMater = almaMater { self.almaMater = almaMater }
        if let gradYear = gradYear { self.gradYear = gradYear }
        if let job = job { self.job = job }
        if let workLocation = workLocation { self.workLocation = workLocation }
        if let relationStatus = relationStatus { self.relationStatus = relationStatus }
        if let sexuality = sexuality { self.sexuality = sexuality }
        if let gender = gender { self.gender = gender }
        
        Log.debug("📱 ProfileModel: Local state updated successfully")
        
        if parameters["latitude"] != nil || parameters["longitude"] != nil {
            Task { await self.updateAddress() }
        }
    }

    // MARK: - Profile Update Struct

    struct ProfileUpdateData {
        let name: String?
        let birthdate: String?
        let interests: [String]?
        let bio: String?
        let latitude: Double?
        let longitude: Double?
        let almaMater: String?
        let gradYear: String?
        let job: String?
        let workLocation: String?
        let relationStatus: String?
        let sexuality: String?
        let gender: String?
        let profileImage: UIImage?
        let extraImages: [UIImage?]
        let isOnboarding: Bool

        init(
            name: String? = nil, birthdate: String? = nil, interests: [String]? = nil,
            bio: String? = nil, latitude: Double? = nil, longitude: Double? = nil,
            almaMater: String? = nil, gradYear: String? = nil, job: String? = nil, workLocation: String? = nil,
            relationStatus: String? = nil, sexuality: String? = nil, gender: String? = nil,
            profileImage: UIImage? = nil, extraImages: [UIImage?] = [nil, nil], isOnboarding: Bool = false
        ) {
            self.name = name; self.birthdate = birthdate; self.interests = interests
            self.bio = bio; self.latitude = latitude; self.longitude = longitude
            self.almaMater = almaMater; self.gradYear = gradYear; self.job = job; self.workLocation = workLocation
            self.relationStatus = relationStatus; self.sexuality = sexuality; self.gender = gender
            self.profileImage = profileImage; self.extraImages = extraImages; self.isOnboarding = isOnboarding
        }
    }

    // swiftlint:disable cyclomatic_complexity
    func updateProfile(
        name: String? = nil,
        birthdate: String? = nil,
        interests: [String]? = nil,
        bio: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        almaMater: String? = nil,
        gradYear: String? = nil,
        job: String? = nil,
        workLocation: String? = nil,
        relationStatus: String? = nil,
        sexuality: String? = nil,
        gender: String? = nil,
        profileImage: UIImage? = nil,
        extraImages: [UIImage?] = [nil, nil],
        isOnboarding: Bool = false,
        completion: @escaping (Result<Void, NetworkError>) -> Void
    ) {
        // TODO: Refactor to reduce cyclomatic complexity - consider using a builder pattern or configuration object
        let updateData = ProfileUpdateData(
            name: name, birthdate: birthdate, interests: interests, bio: bio,
            latitude: latitude, longitude: longitude, almaMater: almaMater, gradYear: gradYear,
            job: job, workLocation: workLocation, relationStatus: relationStatus,
            sexuality: sexuality, gender: gender, profileImage: profileImage,
            extraImages: extraImages, isOnboarding: isOnboarding
        )
        handleImageUploadAndUpdate(updateData: updateData, completion: completion)
                            }
    // swiftlint:enable cyclomatic_complexity

    // Helper to handle image upload and call completion
    private func handleImageUploadAndUpdate(
        updateData: ProfileUpdateData,
        completion: @escaping (Result<Void, NetworkError>) -> Void
    ) {
        uploadAllImages(profileImage: updateData.profileImage, extraImages: updateData.extraImages) { [weak self] imageResult in
            guard let self = self else { return }
            switch imageResult {
                    case .failure(let error):
                        completion(.failure(error))
            case .success:
                self.handleProfileUpdateRequest(updateData: updateData, completion: completion)
                    }
                }
            }

    // Aggressively refactored to reduce cyclomatic complexity
    private func handleProfileUpdateRequest(
        updateData: ProfileUpdateData,
        completion: @escaping (Result<Void, NetworkError>) -> Void
    ) {
        let parameters = buildProfileUpdateParameters(updateData: updateData)
        Log.debug("📱 ProfileModel: handleProfileUpdateRequest - parameters: \(parameters)")
        Log.debug("📱 ProfileModel: endpoint will be: \(updateData.isOnboarding ? "/onboard" : "/edit-profile")")
        
        if parameters.isEmpty {
            Log.debug("📱 ProfileModel: No parameters to update, returning success")
            completion(.success(()))
            return
        }
        let endpoint = updateData.isOnboarding ? "/onboard" : "/edit-profile"
        performProfileUpdateNetworkRequest(endpoint: endpoint, parameters: parameters) { [weak self] result in
            guard let self = self else { return }
            Log.debug("📱 ProfileModel: Network request completed with result: \(result)")
            self.processProfileUpdateResult(
                result: result,
                updateData: updateData,
                parameters: parameters,
                completion: completion
            )
        }
    }

    // Helper: Build parameters
    private func buildProfileUpdateParameters(updateData: ProfileUpdateData) -> [String: Any] {
        // Debug: Log what's being sent to the backend
        print("🔍 DEBUG: Building profile update parameters")
        print("🔍 DEBUG: - gradYear: \(updateData.gradYear ?? "nil")")
        print("🔍 DEBUG: - almaMater: \(updateData.almaMater ?? "nil")")
        
        return buildChangedParameters(
            name: updateData.name,
            birthdate: updateData.birthdate,
            interests: updateData.interests,
            bio: updateData.bio,
            latitude: updateData.latitude,
            longitude: updateData.longitude,
            almaMater: updateData.almaMater,
            gradYear: updateData.gradYear,
            job: updateData.job,
            workLocation: updateData.workLocation,
            relationStatus: updateData.relationStatus,
            sexuality: updateData.sexuality,
            gender: updateData.gender
        )
    }

    // Helper: Perform network request
    private func performProfileUpdateNetworkRequest(
        endpoint: String,
        parameters: [String: Any],
        completion: @escaping (Result<ProfileUpdateResponse, NetworkError>) -> Void
    ) {
        NetworkManager.shared.post(endpoint: endpoint, parameters: parameters, completion: completion)
    }

    // Helper: Process result and update local state
    private func processProfileUpdateResult(
        result: Result<ProfileUpdateResponse, NetworkError>,
        updateData: ProfileUpdateData,
        parameters: [String: Any],
        completion: @escaping (Result<Void, NetworkError>) -> Void
    ) {
        Log.debug("📱 ProfileModel: Processing profile update result")
        switch result {
        case .success(_):
            Log.debug("📱 ProfileModel: Profile update successful, updating local state")
            self.updateLocalState(
                name: updateData.name,
                birthdate: updateData.birthdate,
                interests: updateData.interests,
                bio: updateData.bio,
                latitude: updateData.latitude,
                longitude: updateData.longitude,
                almaMater: updateData.almaMater,
                gradYear: updateData.gradYear,
                job: updateData.job,
                workLocation: updateData.workLocation,
                relationStatus: updateData.relationStatus,
                sexuality: updateData.sexuality,
                gender: updateData.gender,
                parameters: parameters
            )
            Log.debug("📱 ProfileModel: Local state updated, calling completion with success")
            completion(.success(()))
        case .failure(let error):
            Log.debug("📱 ProfileModel: Profile update failed with error: \(error)")
            completion(.failure(error))
        }
    }

    /**
     * Uploads a single image to the backend.
     *
     * - Parameters:
     *   - image: The UIImage to upload
     *   - photoId: The existing photo ID to update (nil for new photos)
     *   - isProfilePic: Whether this is a profile picture
     *   - completion: Completion handler with result
     */
    private func uploadImage(_ image: UIImage, photoId: String?, isProfilePic: Bool, completion: @escaping (Result<Void, NetworkError>) -> Void) {
        // Convert UIImage to base64
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(.networkError(NSError(domain: "ProfileModel", code: 400, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"]))))
            return
        }

        let base64String = imageData.base64EncodedString()

        // Determine endpoint and parameters based on whether we're updating or creating
        let endpoint: String
        let parameters: [String: Any]

        if let photoId = photoId {
            // Updating existing photo
            endpoint = "/userImageUpdate"
            parameters = [
                "data": base64String,
                "photoId": photoId
            ]
        } else {
            // Creating new photo
            endpoint = "/userImage"
            parameters = [
                "data": base64String,
                "isProfilePic": isProfilePic
            ]
        }

        NetworkManager.shared.post(endpoint: endpoint, parameters: parameters) { (result: Result<EditProfileResponse, NetworkError>) in
            DispatchQueue.main.async {
                switch result {
                case .success(_):
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
            Log.debug("Geocoding error: \(error.localizedDescription)")
        }
    }

    // MARK: - Clear Data

    /**
     * Clears all profile data and resets the model to its initial state.
     * This method is typically called when the user logs out.
     */
    func clearData() {
        Log.debug("ProfileModel: clearData resetting verified flag")
        name = ""
        phone = ""
        onboarding = false
        verified = false
        id = ""
        // Don't clear userId since we're using Firebase Auth
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
     *
     * - Parameter completion: Optional completion handler called when all images are loaded
     */
    func loadAllImages(completion: (() -> Void)? = nil) {
        let imageLoadGroup = DispatchGroup()
        isProfileImageLoading = true

        // Load profile image
        if let profileURL = profileImageURL {
            imageLoadGroup.enter()
            KingfisherManager.shared.retrieveImage(with: profileURL) { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let imageResult):
                        self?.profileUIImage = imageResult.image
                        Log.debug("Profile image loaded and stored")
                    case .failure(let error):
                        Log.error("Failed to load profile image: \(error.localizedDescription)")
                        self?.profileUIImage = nil
                    }
                    self?.isProfileImageLoading = false
                    imageLoadGroup.leave()
                }
            }
        } else {
            isProfileImageLoading = false
        }

        // Load extra images
        for (index, url) in extraImageURLs.enumerated() {
            imageLoadGroup.enter()
            KingfisherManager.shared.retrieveImage(with: url) { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let imageResult):
                        if index < self?.extraUIImages.count ?? 0 {
                            self?.extraUIImages[index] = imageResult.image
                        }
                        Log.debug("Extra image \(index) loaded and stored")
                    case .failure(let error):
                        Log.error("Failed to load extra image \(index): \(error.localizedDescription)")
                        if index < self?.extraUIImages.count ?? 0 {
                            self?.extraUIImages[index] = nil
                        }
                    }
                    imageLoadGroup.leave()
                }
            }
        }

        // Call completion when all images are loaded
        imageLoadGroup.notify(queue: .main) {
            completion?()
        }
    }

    /**
     * Clears all loaded images from memory.
     */
    func clearImages() {
        profileUIImage = nil
        extraUIImages = [nil, nil]
    }

    /**
     * Convenience method to fetch profile and load all images.
     * This combines fetchProfile() and loadAllImages() for easier use in views.
     *
     * - Parameter completion: Completion handler with result and loaded images status
     */
    func fetchProfileWithImages(completion: @escaping (Result<ProfileData, NetworkError>) -> Void) {
        fetchProfile { result in
            switch result {
            case .success(let profileData):
                // After successful profile fetch, load all images
                self.loadAllImages {
                    // Images loaded, call completion with success
                    completion(.success(profileData))
                }
            case .failure(let error):
                // Profile fetch failed, call completion with error
                completion(.failure(error))
            }
        }
    }
    
    /**
     * Calculates the profile completion progress based on 10 optional fields.
     * Each field contributes 10% (100% ÷ 10) to the total progress.
     *
     * Tracked fields:
     * 1. Profile picture
     * 2. Gender
     * 3. Relationship status
     * 4. Interests/hobbies
     * 5. Extra photo 1
     * 6. Extra photo 2
     * 7. Workplace (workLocation)
     * 8. Role (job)
     * 9. Bio
     * 10. City
     *
     * - Returns: Progress value between 0.0 and 1.0
     */
    func calculateProfileProgress() -> Double {
        var completedFields = 0
        let totalFields = 10
        
        // 1. Profile picture
        if profileUIImage != nil {
            completedFields += 1
        }
        
        // 2. Gender
        if !gender.isEmpty {
            completedFields += 1
        }
        
        // 3. Relationship status
        if !relationStatus.isEmpty {
            completedFields += 1
        }
        
        // 4. Interests/hobbies
        if !interests.isEmpty {
            completedFields += 1
        }
        
        // 5. Extra photo 1
        if extraUIImages[0] != nil {
            completedFields += 1
        }
        
        // 6. Extra photo 2
        if extraUIImages[1] != nil {
            completedFields += 1
        }
        
        // 7. Workplace (workLocation)
        if !workLocation.isEmpty {
            completedFields += 1
        }
        
        // 8. Role (job)
        if !job.isEmpty {
            completedFields += 1
        }
        
        // 9. Bio
        if !bio.isEmpty {
            completedFields += 1
        }
        
        // 10. City
        if !address.isEmpty {
            completedFields += 1
        }
        
        return Double(completedFields) / Double(totalFields)
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
