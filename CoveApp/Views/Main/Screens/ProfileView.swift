//
//  ProfileView.swift
//  Cove
//
//  Created by Nesib Muhedin


import SwiftUI
import CoreLocation
import MapKit
import PhotosUI
import Kingfisher

// TODO: Default profile picture
// TODO: Consider a view and edit option up top to swipe like hinge instead

// MARK: - Profile Header Component

// Text component for the profile
struct ProfileText: View {
    let text: String
    let isPlaceholder: Bool
    var body: some View {
        Text(text.lowercased())
            .font(.LibreBodoni(size: 15))
            // lighter grey color for place holder
            .foregroundColor(isPlaceholder ? Colors.k6F6F73 : Colors.primaryDark)
    }
}


struct ProfileHeader: View {
    let name: String
    let workLocation: String
    let gender: String
    let relationStatus: String
    let job: String
    let profileImageURL: URL?
    let age: Int?
    let address: String
    let isEditing: Bool
    let editingProfileImage: UIImage?
    let onNameChange: (String) -> Void
    let onWorkLocationChange: (String) -> Void
    let onGenderChange: (String) -> Void
    let onRelationStatusChange: (String) -> Void
    let onJobChange: (String) -> Void
    let onLocationSelect: () -> Void
    let onProfileImageChange: (UIImage?) -> Void
    
    @State private var selectedItem: PhotosPickerItem?
    @State private var isPressed = false
    @EnvironmentObject var appController: AppController
    
    var body: some View {
        VStack(spacing: 10) {
            // MARK: - Profile Photo
            PhotosPicker(selection: $selectedItem, matching: .images) {
                ZStack {
                    if let profileImage = editingProfileImage ?? appController.profileModel.profileUIImage {
                        Image(uiImage: profileImage)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: 200, maxHeight: 200)
                            .clipShape(Circle())
                    } else {
                        // default profile photo
                        Image("default_user_pfp")
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: 200, maxHeight: 200)
                            .clipShape(Circle())
                            .onAppear {
                                print("📸 ProfileHeader: Displaying placeholder image")
                            }
                    }
                    
                    // Overlay for editing
                    // TODO: actually we should have an x up top and a user can only change after they remove their current picture
                    if isEditing {
                        Circle()
                            .fill(Color.black.opacity(isPressed ? 0.7 : 0.3))
                            .frame(maxWidth: 200, maxHeight: 200)
                        
                        Text("change")
                            .font(.LibreBodoni(size: 16))
                            .foregroundColor(.white)
                    }
                }
            }
            .disabled(!isEditing)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
            .onTapGesture {
                if isEditing {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.easeInOut(duration: 0.1)) {
                            isPressed = false
                        }
                    }
                }
            }
            // TODO: what is selectedItem? 
            .onChange(of: selectedItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        onProfileImageChange(image)
                    }
                }
            }
            
            // MARK: - Profile header
            if isEditing {
                TextField("Name", text: .constant(name), onCommit: { onNameChange(name) })
                    .font(.LibreBodoniMedium(size: 35))
                    .foregroundColor(Colors.primaryDark)
                    .multilineTextAlignment(.center)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(.vertical, 4)
                    // TODO: make the underline a view modifier
                    .overlay(
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(Colors.primaryDark.opacity(0.3))
                            .offset(y: 20)
                    )
                    .onChange(of: name) { _, newValue in
                        onNameChange(newValue)
                    }
            } else {
                Text(name.lowercased())
                    .font(.LibreBodoniMedium(size: 35))
                    .foregroundColor(Colors.primaryDark)
            }
            
            VStack(alignment: .leading, spacing: 10) {
                if isEditing {
                    Button(action: onLocationSelect) {
                        HStack(spacing: 6) {
                            Text(address.isEmpty ? "add your location" : address.lowercased())
                                .font(.LibreBodoni(size: 15))
                                .foregroundColor(address.isEmpty ? Colors.k6F6F73 : Colors.primaryDark)
                                .multilineTextAlignment(.center)
                            
                            Image(systemName: "location.fill")
                                .foregroundColor(Colors.primaryDark)
                                .font(.system(size: 10))
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 4)
                    }
                } else {
                    ProfileText(
                        text: address.isEmpty ? "add your location" : address,
                        isPlaceholder: address.isEmpty
                    ).frame(maxWidth: .infinity, alignment: .center)
                }
                
                HStack() {
                    Text(age.map(String.init) ?? "21")
                        .font(.LibreBodoni(size: 20))
                        .foregroundColor(Colors.primaryDark)
                    
                    Spacer()
                    
                    Image("more-info")
                    
                    if isEditing {
                        // TODO: this should maybe also be a drop down select
                        TextField("Gender", text: .constant(gender), onCommit: { onGenderChange(gender) })
                            .font(.LibreBodoni(size: 15))
                            .foregroundColor(Colors.primaryDark)
                            .multilineTextAlignment(.center)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding(.vertical, 4)
                            .overlay(
                                Rectangle()
                                    .frame(height: 1)
                                    .foregroundColor(Colors.primaryDark.opacity(0.3))
                                    .offset(y: 12)
                            )
                            .onChange(of: gender) { _, newValue in
                                onGenderChange(newValue)
                            }
                    } else {
                        ProfileText(
                            text: gender.isEmpty ? "add gender" : gender,
                            isPlaceholder: gender.isEmpty
                        )
                    }
                    
                    Spacer()
                    
                    Image("person-fill")
                    
                    if isEditing {
                        RelationStatusPicker(selectedStatus: relationStatus, onStatusChange: onRelationStatusChange)
                    } else {
                        ProfileText(
                            text: relationStatus.isEmpty ? "add status" : relationStatus,
                            isPlaceholder: relationStatus.isEmpty
                        )
                    }
                }.padding(.horizontal, 5)
                
                HStack() {
                    Image(systemName: "briefcase")
                        .foregroundStyle(Colors.k6B6B6B)
                    
                    if isEditing {
                        HStack {
                            TextField("Job", text: .constant(job), onCommit: { onJobChange(job) })
                                .font(.LibreBodoni(size: 15))
                                .foregroundColor(Colors.primaryDark)
                                .textFieldStyle(PlainTextFieldStyle())
                                .padding(.vertical, 4)
                                .overlay(
                                    Rectangle()
                                        .frame(height: 1)
                                        .foregroundColor(Colors.primaryDark.opacity(0.3))
                                        .offset(y: 12)
                                )
                                .onChange(of: job) { _, newValue in
                                    onJobChange(newValue)
                                }
                            
                            Text("@")
                                .font(.LibreBodoni(size: 15))
                                .foregroundColor(Colors.primaryDark)
                            
                            TextField("Work Location", text: .constant(workLocation), onCommit: { onWorkLocationChange(workLocation) })
                                .font(.LibreBodoni(size: 15))
                                .foregroundColor(Colors.primaryDark)
                                .textFieldStyle(PlainTextFieldStyle())
                                .padding(.vertical, 4)
                                .overlay(
                                    Rectangle()
                                        .frame(height: 1)
                                        .foregroundColor(Colors.primaryDark.opacity(0.3))
                                        .offset(y: 12)
                                )
                                .onChange(of: workLocation) { _, newValue in
                                    onWorkLocationChange(newValue)
                                }
                        }
                    } else {
                        if job.isEmpty || workLocation.isEmpty {
                            ProfileText(text: "add your work", isPlaceholder: true)
                        } else {
                            ProfileText(text: "\(job) @ \(workLocation)", isPlaceholder: false)
                        }
                    }
                }
            }
        }
        .onAppear {
            print("📸 ProfileHeader: profileImage=\(profileImageURL != nil ? "loaded" : "nil")")
        }
        .onChange(of: profileImageURL) { _, newURL in
            print("📸 ProfileHeader: profileImage changed to \(newURL != nil ? "loaded" : "nil")")
        }
    }
}

// MARK: - Relation Status Picker
struct RelationStatusPicker: View {
    let selectedStatus: String
    let onStatusChange: (String) -> Void
    @State private var showingPicker = false
    
    private let statusOptions = ["Single", "Taken", "It's Complicated"]
    
    var body: some View {
        Button(action: {
            showingPicker = true
        }) {
            Text(selectedStatus.isEmpty ? "add status" : selectedStatus.lowercased())
                .font(.LibreBodoni(size: 15))
                .foregroundColor(selectedStatus.isEmpty ? Colors.k6F6F73 : Colors.primaryDark)
                .padding(.vertical, 4)
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Colors.primaryDark.opacity(0.3))
                        .offset(y: 12)
                )
        }
        .sheet(isPresented: $showingPicker) {
            VStack(spacing: 20) {
                Text("relationship status")
                    .font(.LibreBodoni(size: 24))
                    .foregroundColor(Colors.primaryDark)
                
                ForEach(statusOptions, id: \.self) { status in
                    Button(action: {
                        onStatusChange(status)
                        showingPicker = false
                    }) {
                        HStack {
                            Text(status)
                                .font(.LibreBodoni(size: 18))
                                .foregroundColor(Colors.primaryDark)
                            Spacer()
                            if selectedStatus == status {
                                Image(systemName: "checkmark")
                                    .foregroundColor(Colors.primaryDark)
                            }
                        }
                        .padding()
                        .background(selectedStatus == status ? Color.gray.opacity(0.1) : Color.clear)
                        .cornerRadius(10)
                    }
                }
                
                Spacer()
            }
            .padding()
            .presentationDetents([.medium])
        }
    }
}

// MARK: - Bio Component
struct BioSection: View {
    let bio: String
    let isEditing: Bool
    let onBioChange: (String) -> Void
    
    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            HStack {
                if isEditing {
                    TextField("Add your bio...", text: .constant(bio), axis: .vertical)
                        .font(.LeagueSpartan(size: 14))
                        .foregroundStyle(Colors.k6F6F73)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, minHeight: 50, maxHeight: .infinity, alignment: .leading)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Colors.primaryDark.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .onChange(of: bio) { _, newValue in
                            onBioChange(newValue)
                        }
                } else {
                    Text(bio.isEmpty ? "add your bio" : bio.lowercased())
                        .font(.LeagueSpartan(size: 14))
                        .foregroundStyle(bio.isEmpty ? Colors.k6F6F73 : Colors.k6F6F73)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, minHeight: 50, maxHeight: .infinity, alignment: .leading)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                        )
                }
            }
        }
        .padding()
    }
}

// MARK: - Interests Component
struct InterestsSection: View {
    let interests: [String]
    let isEditing: Bool
    let onInterestsChange: ([String]) -> Void
    @State private var showingHobbiesSheet = false
    
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
            
            if interests.isEmpty && !isEditing {
                StaticHobbyPill(text: "whoops! add your passtimes!", textColor: Colors.k6F6F73)
            } else {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(interests, id: \.self) { hobby in
                        ZStack {
                            StaticHobbyPill(text: hobby, textColor: Colors.k6F6F73)
                                
                                if isEditing {
                                HStack {
                                    Spacer()
                                    Button(action: {
                                        var newInterests = interests
                                        newInterests.removeAll { $0 == hobby }
                                        onInterestsChange(newInterests)
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.gray)
                                            .font(.system(size: 16))
                                    }
                                    .padding(.trailing, 8)
                                }
                            }
                        }
                    }
                    
                    if isEditing {
                        StaticHobbyPill(
                            text: "add hobby",
                            emoji: "➕",
                            textColor: Colors.primaryDark
                        )
                        .onTapGesture {
                            showingHobbiesSheet = true
                        }
                    }
                }
            }
        }
        .padding()
        .sheet(isPresented: $showingHobbiesSheet) {
            HobbiesSelectionView(
                selectedHobbies: Set(interests),
                onHobbiesSelected: { selectedHobbies in
                    onInterestsChange(Array(selectedHobbies))
                    showingHobbiesSheet = false
                }
            )
        }
    }
}

// MARK: - Location Selection View
struct LocationSelectionView: View {
    let currentAddress: String
    let onLocationSelected: (String, CLLocationCoordinate2D) -> Void
    @State private var userLocation: CLLocation?
    @State private var coordinate: CLLocationCoordinate2D?
    @State private var selectedAddress: String = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                MapView(userLocation: $userLocation, coordinate: $coordinate)
                    .onChange(of: coordinate) { _, newCoordinate in
                        if let coord = newCoordinate {
                            Task {
                                selectedAddress = await getLocationName(latitude: coord.latitude, longitude: coord.longitude)
                            }
                        }
                    }
                
                VStack(spacing: 16) {
                    Text("selected location")
                        .font(.LibreBodoni(size: 18))
                        .foregroundColor(Colors.primaryDark)
                    
                    Text(selectedAddress.isEmpty ? "Tap on the map to select a location" : selectedAddress.lowercased())
                        .font(.LeagueSpartan(size: 14))
                        .foregroundColor(Colors.k6F6F73)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button(action: {
                        if let coord = coordinate, !selectedAddress.isEmpty {
                            onLocationSelected(selectedAddress, coord)
                            dismiss()
                        }
                    }) {
                        Text("confirm location")
                            .font(.LibreBodoni(size: 16))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Colors.primaryDark)
                            )
                    }
                    .disabled(selectedAddress.isEmpty)
                    .opacity(selectedAddress.isEmpty ? 0.5 : 1.0)
                }
                .padding()
            }
            .navigationTitle("Select Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func getLocationName(latitude: Double, longitude: Double) async -> String {
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
}

// MARK: - Hobbies Selection View
struct HobbiesSelectionView: View {
    let selectedHobbies: Set<String>
    let onHobbiesSelected: (Set<String>) -> Void
    @State private var currentSelection: Set<String>
    @State private var searchText: String = ""
    @Environment(\.dismiss) private var dismiss
    
    init(selectedHobbies: Set<String>, onHobbiesSelected: @escaping (Set<String>) -> Void) {
        self.selectedHobbies = selectedHobbies
        self.onHobbiesSelected = onHobbiesSelected
        self._currentSelection = State(initialValue: selectedHobbies)
    }
    
    private let hobbyCategories: [(String, [(String, String)])] = [
        ("Sports & Fitness 🏃‍♀️", [
            ("Soccer Teams", "⚽️"),
            ("Basketball Leagues", "🏀"),
            ("Tennis Groups", "🎾"),
            ("Hiking Groups", "🥾"),
            ("Yoga Classes", "🧘‍♀️"),
            ("Surfing Meetups", "🏄‍♀️"),
            ("Rock Climbing", "🧗‍♀️"),
            ("Swimming Clubs", "🏊‍♀️"),
            ("Running Groups", "🏃‍♀️"),
            ("Volleyball Teams", "🏐"),
            ("Spin Classes", "🚴‍♀️"),
            ("Boxing Clubs", "🥊"),
            ("CrossFit Groups", "💪"),
            ("Dance Fitness", "💃"),
            ("Beach Volleyball", "🏖️"),
            ("Ultimate Frisbee", "🥏"),
            ("Pickleball Clubs", "🏓"),
            ("Golf Leagues", "⛳️")
        ]),
        ("Creative Pursuits 🎨", [
            ("Art Museums", "🖼️"),
            ("Pottery Classes", "🏺"),
            ("Dance Studios", "💃"),
            ("Music Festivals", "🎵"),
            ("Theater Groups", "🎭"),
            ("Cooking Classes", "👨‍🍳"),
            ("Craft Workshops", "✂️"),
            ("Writing Circles", "✍️"),
            ("Film Clubs", "🎬"),
            ("Photography Walks", "📸"),
            ("Painting Classes", "🎨"),
            ("Sculpture Workshops", "🗿"),
            ("Jewelry Making", "💍"),
            ("Glass Blowing", "🔥"),
            ("Digital Art Clubs", "🖥️"),
            ("Street Art Tours", "🎯"),
            ("Fashion Design", "👗"),
            ("Woodworking", "🪚")
        ]),
        ("Entertainment 🎉", [
            ("Cocktail Bars", "🍸"),
            ("Clubs", "🍷"),
            ("Wine Tastings", "🍷"),
            ("Comedy Clubs", "😄"),
            ("Karaoke Nights", "🎤"),
            ("Escape Rooms", "🔐"),
            ("Bowling Leagues", "🎳"),
            ("Live Music Venues", "🎸"),
            ("Jazz Clubs", "🎺"),
            ("Rooftop Bars", "🌆"),
            ("Beer Gardens", "🍺"),
            ("Game Nights", "🎲"),
            ("Dance Clubs", "💃"),
            ("Piano Bars", "🎹"),
            ("Magic Shows", "🎩"),
            ("Burlesque Shows", "✨"),
            ("Improv Classes", "🎭"),
            ("Casino Nights", "🎰")
        ]),
        ("Social Activities 🌟", [
            ("Book Clubs", "📚"),
            ("Travel Groups", "✈️"),
            ("Founders Groups", "💻"),
            ("Chess Clubs", "♟️"),
            ("Volunteer Groups", "🤝"),
            ("Language Exchange", "🗣️"),
            ("Food Tours", "🍽️"),
            ("Coffee Meetups", "☕️"),
            ("Tech Meetups", "💻"),
            ("Gardening Clubs", "🌱"),
            ("Cultural Events", "🎪"),
            ("Philosophy Clubs", "🤔"),
            ("Astronomy Groups", "🔭"),
            ("Hiking Meetups", "🥾"),
            ("Wine & Paint", "🎨"),
            ("Cooking Classes", "👨‍🍳"),
            ("Board Game Nights", "🎲"),
            ("Trivia Teams", "🧠")
        ])
    ]
    
    private var filteredCategories: [(String, [(String, String)])] {
        if searchText.isEmpty {
            return hobbyCategories
        }
        
        return hobbyCategories.compactMap { category in
            let filteredHobbies = category.1.filter { hobby in
                hobby.0.lowercased().contains(searchText.lowercased())
            }
            
            if filteredHobbies.isEmpty {
                return nil
            }
            
            return (category.0, filteredHobbies)
        }
    }
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search hobbies...", text: $searchText)
                        .font(.LeagueSpartan(size: 14))
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding()
                
                // Hobbies grid
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        ForEach(filteredCategories, id: \.0) { category in
                            VStack(alignment: .leading, spacing: 12) {
                                Text(category.0)
                                    .font(.LeagueSpartan(size: 16))
                                    .foregroundStyle(Colors.primaryLight)
                                    .padding(.horizontal)
                                
                                LazyVGrid(columns: columns, spacing: 12) {
                                    ForEach(category.1, id: \.0) { hobby in
                                        Button(action: {
                                            if currentSelection.contains(hobby.0) {
                                                currentSelection.remove(hobby.0)
                                            } else {
                                                currentSelection.insert(hobby.0)
                                            }
                                        }) {
                                            HobbyPill(
                                                text: hobby.0,
                                                emoji: hobby.1,
                                                isSelected: currentSelection.contains(hobby.0)
                                            ) {
                                                if currentSelection.contains(hobby.0) {
                                                    currentSelection.remove(hobby.0)
                                                } else {
                                                    currentSelection.insert(hobby.0)
                                            }
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Hobbies")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onHobbiesSelected(currentSelection)
                    }
                }
            }
        }
    }
}

// MARK: - Extra Photo Component
struct ExtraPhotoView: View {
    let imageIndex: Int
    let isEditing: Bool
    let editingImage: UIImage?
    let onImageChange: (UIImage?) -> Void
    
    @State private var selectedItem: PhotosPickerItem?
    @State private var isPressed = false
    @EnvironmentObject var appController: AppController
    
    var body: some View {
        PhotosPicker(selection: $selectedItem, matching: .images) {
            ZStack {
                if let extraImage = editingImage ?? (appController.profileModel.extraUIImages.indices.contains(imageIndex) ? appController.profileModel.extraUIImages[imageIndex] : nil) {
                    Image(uiImage: extraImage)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: AppConstants.SystemSize.width*0.8)
                } else if isEditing {
                    // Show empty space with border when editing and no image
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: AppConstants.SystemSize.width*0.8, height: 200)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .onAppear {
                            print("📸 ExtraPhotoView: Displaying empty space (editing mode)")
                        }
                } else {
                    // Show nothing when not editing and no image
                    EmptyView()
                        .onAppear {
                            print("📸 ExtraPhotoView: No image to display (not editing)")
                        }
                }
                
                if isEditing {
                    Rectangle()
                        .fill(Color.black.opacity(isPressed ? 0.7 : 0.3))
                        .frame(maxWidth: AppConstants.SystemSize.width*0.8)
                    
                    Text((editingImage ?? (appController.profileModel.extraUIImages.indices.contains(imageIndex) ? appController.profileModel.extraUIImages[imageIndex] : nil)) == nil ? "add picture" : "change")
                        .font(.LibreBodoni(size: 16))
                        .foregroundColor(.white)
                }
            }
        }
        .disabled(!isEditing)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onTapGesture {
            if isEditing {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = false
                    }
                }
            }
        }
        .onChange(of: selectedItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    onImageChange(image)
                }
            }
        }
    }
}

// MARK: - Main Profile View
struct ProfileView: View {
    @EnvironmentObject var appController: AppController
    @State private var isEditing = false
    @State private var showingLocationSheet = false
    @State private var isSaving = false
    
    // Local editing state
    @State private var editingName: String = ""
    @State private var editingWorkLocation: String = ""
    @State private var editingGender: String = ""
    @State private var editingRelationStatus: String = ""
    @State private var editingJob: String = ""
    @State private var editingBio: String = ""
    @State private var editingInterests: [String] = []
    @State private var editingAddress: String = ""
    @State private var editingLatitude: Double?
    @State private var editingLongitude: Double?
    @State private var editingProfileImage: UIImage?
    @State private var editingExtraImages: [UIImage?] = [nil, nil]
    
    var body: some View {
        ZStack {
            Colors.faf8f4
                .ignoresSafeArea()
            
            VStack {
                // Custom Header
                HStack(alignment: .center) {
                    Text("cove")
                        .font(.LibreBodoniBold(size: 32))
                        .foregroundColor(Colors.primaryDark)
                    Spacer()
                    HStack(spacing: 18) {
                        // Edit/Save button
                        Button(action: {
                        if isEditing {
                            // Show loading spinner immediately
                            isSaving = true
                            
                            // Save changes and wait for completion before toggling
                            saveChanges { success in
                                DispatchQueue.main.async {
                                    isSaving = false
                                    if success {
                                        isEditing = false
                                    }
                                    // If failed, stay in editing mode so user can try again
                                }
                            }
                        } else {
                            // Enter editing mode
                            isEditing = true
                            initializeEditingState()
                        }
                        }) {
                        if isSaving {
                            ProgressView()
                                .scaleEffect(0.8)
                                .foregroundColor(Colors.primaryDark)
                        } else {
                            (isEditing ? Image(systemName: "checkmark") : Image("edit_button"))
                                .foregroundColor(Colors.primaryDark)
                                .frame(width: 26, height: 26)
                        }
                    }
                    .disabled(isSaving)
                }
                }
                .padding(.horizontal, 10)
                .padding(.top, 24)
                .padding(.bottom, 8)

                if appController.profileModel.isLoading {
                    Spacer()
                    ProgressView("Loading profile...")
                        .foregroundColor(Colors.primaryDark)
                    Spacer()
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 20) {
                            ProfileHeader(
                                name: isEditing ? editingName : appController.profileModel.name,
                                workLocation: isEditing ? editingWorkLocation : appController.profileModel.workLocation,
                                gender: isEditing ? editingGender : appController.profileModel.gender,
                                relationStatus: isEditing ? editingRelationStatus : appController.profileModel.relationStatus,
                                job: isEditing ? editingJob : appController.profileModel.job,
                                profileImageURL: isEditing ? nil : appController.profileModel.profileImageURL,
                                age: appController.profileModel.calculatedAge,
                                address: isEditing ? editingAddress : appController.profileModel.address,
                                isEditing: isEditing,
                                editingProfileImage: editingProfileImage,
                                onNameChange: { editingName = $0 },
                                onWorkLocationChange: { editingWorkLocation = $0 },
                                onGenderChange: { editingGender = $0 },
                                onRelationStatusChange: { editingRelationStatus = $0 },
                                onJobChange: { editingJob = $0 },
                                onLocationSelect: {
                                    showingLocationSheet = true
                                },
                                onProfileImageChange: { editingProfileImage = $0 }
                            ).frame(maxWidth: 270)
                            .onAppear {
                                print("📸 ProfileHeader: profileImage=\(appController.profileModel.profileImageURL != nil ? "loaded" : "nil")")
                            }
                            .onChange(of: appController.profileModel.profileImageURL) { _, newURL in
                                print("📸 ProfileHeader: profileImage changed to \(newURL != nil ? "loaded" : "nil")")
                            }
                            
                            ExtraPhotoView(
                                imageIndex: 0,
                                isEditing: isEditing,
                                editingImage: editingExtraImages[0],
                                onImageChange: { editingExtraImages[0] = $0 }
                            )
                            .onAppear {
                                print("📸 ExtraPhotoView 1: imageURL=\(appController.profileModel.extraImageURLs.first?.absoluteString ?? "nil")")
                            }
                            .onChange(of: appController.profileModel.extraImageURLs.first) { _, newURL in
                                print("📸 ExtraPhotoView 1: imageURL changed to \(newURL?.absoluteString ?? "nil")")
                            }
                            
                            BioSection(
                                bio: isEditing ? editingBio : appController.profileModel.bio,
                                isEditing: isEditing,
                                onBioChange: { editingBio = $0 }
                            )
                            
                            ExtraPhotoView(
                                imageIndex: 1,
                                isEditing: isEditing,
                                editingImage: editingExtraImages[1],
                                onImageChange: { editingExtraImages[1] = $0 }
                            )
                            .onAppear {
                                print("📸 ExtraPhotoView 2: imageURL=\(appController.profileModel.extraImageURLs.dropFirst().first?.absoluteString ?? "nil")")
                            }
                            .onChange(of: appController.profileModel.extraImageURLs.dropFirst().first) { _, newURL in
                                print("📸 ExtraPhotoView 2: imageURL changed to \(newURL?.absoluteString ?? "nil")")
                            }
                            
                            InterestsSection(
                                interests: isEditing ? editingInterests : appController.profileModel.interests,
                                isEditing: isEditing,
                                onInterestsChange: { editingInterests = $0 }
                            )
                        }
                        .padding(.vertical, 20)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .navigationBarBackButtonHidden()
        .sheet(isPresented: $showingLocationSheet) {
            LocationSelectionView(
                currentAddress: editingAddress,
                onLocationSelected: { address, coordinate in
                    editingAddress = address
                    editingLatitude = coordinate.latitude
                    editingLongitude = coordinate.longitude
                }
            )
        }
        .task {
            print("📸 ProfileView: Current ProfileModel state:")
            print("📸 ProfileModel profileImageURL: \(appController.profileModel.profileImageURL?.absoluteString ?? "nil")")
            print("📸 ProfileModel extraImageURLs: \(appController.profileModel.extraImageURLs.map { $0.absoluteString })")
            
            // Profile data should already be loaded during login/onboarding
            // No need to fetch again - this was causing redundant network calls
        }
        .onDisappear {
            // Don't cancel requests here - let ProfileModel handle its own lifecycle
            // The image loading should complete naturally
        }
    }
    
    private func initializeEditingState() {
        editingName = appController.profileModel.name
        editingWorkLocation = appController.profileModel.workLocation
        editingGender = appController.profileModel.gender
        editingRelationStatus = appController.profileModel.relationStatus
        editingJob = appController.profileModel.job
        editingBio = appController.profileModel.bio
        editingInterests = appController.profileModel.interests
        editingAddress = appController.profileModel.address
        editingLatitude = appController.profileModel.latitude
        editingLongitude = appController.profileModel.longitude
        // Note: editingProfileImage and editingExtraImages are used only for new images selected during editing
        editingProfileImage = nil
        editingExtraImages = [nil, nil]
    }
    
    private func saveChanges(completion: @escaping (Bool) -> Void) {
        // Check if any changes were actually made
        let hasChanges = editingName != appController.profileModel.name ||
                        editingInterests != appController.profileModel.interests ||
                        editingBio != appController.profileModel.bio ||
                        editingLatitude != appController.profileModel.latitude ||
                        editingLongitude != appController.profileModel.longitude ||
                        editingJob != appController.profileModel.job ||
                        editingWorkLocation != appController.profileModel.workLocation ||
                        editingRelationStatus != appController.profileModel.relationStatus ||
                        editingGender != appController.profileModel.gender ||
                        editingProfileImage != nil ||
                        editingExtraImages.contains { $0 != nil }
        
        if !hasChanges {
            print("📱 No changes detected in ProfileView, skipping save")
            completion(true) // Return success since there's nothing to save
            return
        }
        
        // Update the ProfileModel with all changes (images and text fields)
        appController.profileModel.updateProfile(
            name: editingName,
            interests: editingInterests,
            bio: editingBio,
            latitude: editingLatitude,
            longitude: editingLongitude,
            job: editingJob,
            workLocation: editingWorkLocation,
            relationStatus: editingRelationStatus,
            gender: editingGender,
            profileImage: editingProfileImage,
            extraImages: editingExtraImages
        ) { result in
            switch result {
            case .success:
                print("✅ Profile updated successfully")
                // The ProfileModel will automatically update its properties after successful backend call
                completion(true)
            case .failure(let error):
                print("❌ Failed to update profile: \(error)")
                // TODO: Show error message to user
                completion(false)
            }
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AppController.shared)
}

