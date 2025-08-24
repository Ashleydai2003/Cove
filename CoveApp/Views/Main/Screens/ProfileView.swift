//
//  ProfileView.swift
//  Cove
//
//  Created by Nesib Muhedin

import SwiftUI
import UIKit
import CoreLocation
import PhotosUI
import Kingfisher
import FirebaseAuth

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

@MainActor
struct ProfileHeader: View {
    @Binding var name: String
    @Binding var workLocation: String
    @Binding var gender: String
    @Binding var relationStatus: String
    @Binding var job: String
    @Binding var almaMater: String
    @Binding var gradYear: String
    let profileImageURL: URL?
    let age: Int?
    let address: String
    let isEditing: Bool
    let editingProfileImage: UIImage?
    let progress: Double?
    let onNameChange: (String) -> Void
    let onWorkLocationChange: (String) -> Void
    let onGenderChange: (String) -> Void
    let onRelationStatusChange: (String) -> Void
    let onJobChange: (String) -> Void
    let onAlmaMaterChange: (String) -> Void
    let onGradYearChange: (String) -> Void
    let onLocationSelect: () -> Void
    let onProfileImageChange: (UIImage?) -> Void

    @State private var selectedItem: PhotosPickerItem?
    @State private var isPressed = false
    @EnvironmentObject var appController: AppController

    // Computed property to format grad year as last two digits
    private var formattedGradYear: String {
        if gradYear.count >= 2 {
            return String(gradYear.suffix(2))
        }
        return gradYear
    }

    var body: some View {
        // Capture the @State flag once in a main-actor context; use it everywhere below to avoid
        // referencing 'isPressed' inside non-isolated view-builder closures.
        let pressed = isPressed
        let fallbackImage = appController.profileModel.profileUIImage // main-actor safe
        let isProfileImageLoading = appController.profileModel.isProfileImageLoading // <--- capture here

        VStack(spacing: 8) {
            // Progress text above the photo when incomplete
            if let p = progress, p < 1.0 {
                Text("profile \(Int((max(0, min(1, p)) * 100).rounded()))% complete")
                    .font(.LibreBodoni(size: 14))
                    .foregroundColor(Colors.k6F6F73)
                    .offset(y: -6)
            }

            // MARK: - Profile Photo with tight progress ring
            ZStack {
                if let p = progress {
                    ZStack {
                        Circle()
                            .stroke(Colors.primaryDark.opacity(0.12), style: StrokeStyle(lineWidth: 8))
                        Circle()
                            .trim(from: 0, to: CGFloat(max(0, min(1, p))))
                            .stroke(Colors.primaryDark, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                    }
                    .frame(width: 148, height: 148)
                }

                // Pull main-actor data into local constants BEFORE entering the PhotosPicker content closure.
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    // The closure passed to PhotosPicker is not main-actor-isolated, so we must avoid directly
                    // touching @MainActor properties inside it. We therefore use the pre-computed values captured above.
                    ZStack {
                        if let profileImage = editingProfileImage ?? fallbackImage {
                            Image(uiImage: profileImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 140, height: 140)
                                .clipShape(Circle())
                        } else if isProfileImageLoading { // <--- use the captured value
                            // Show loading state with proper circular shape
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 140, height: 140)
                                .overlay(
                                    ProgressView()
                                        .scaleEffect(1.5)
                                        .tint(Color.white)
                                )
                        } else {
                            // default profile photo only if not loading
                            Image("default_user_pfp")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 140, height: 140)
                                .clipShape(Circle())
                                .onAppear {
                                }
                        }

                        // Overlay for editing
                        // TODO: actually we should have an x up top and a user can only change after they remove their current picture
                        if isEditing {
                            Circle()
                                .fill(Color.black.opacity(pressed ? 0.7 : 0.3))
                                .frame(width: 140, height: 140)

                            Text("change")
                                .font(.LibreBodoni(size: 16))
                                .foregroundColor(.white)
                        }
                    }
                }
                .disabled(!isEditing)
                .animation(.easeInOut(duration: 0.1), value: pressed)
                .onTapGesture {
                    if isEditing {
                        Task { @MainActor in
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
            }

            // MARK: - Profile header
            if isEditing {
                TextField("name", text: $name, onCommit: { onNameChange(name) })
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

            VStack(alignment: .center, spacing: 16) {
                // Top row: Age, Gender, Relationship Status (centered)
                HStack(spacing: 20) {
                    Text(age.map(String.init) ?? "21")
                        .font(.LibreBodoni(size: 20))
                        .foregroundColor(Colors.primaryDark)

                    HStack(spacing: 6) {
                        Image("genderIcon")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 16, height: 16)

                        if isEditing {
                            TextField("gender", text: $gender, onCommit: { onGenderChange(gender) })
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
                                    let lowercasedValue = newValue.lowercased()
                                    gender = lowercasedValue
                                    onGenderChange(lowercasedValue)
                                }
                        } else {
                            ProfileText(
                                text: gender.isEmpty ? "add gender" : gender,
                                isPlaceholder: gender.isEmpty
                            )
                        }
                    }

                    HStack(spacing: 6) {
                        Image("relationshipIcon")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 16, height: 16)

                        if isEditing {
                            RelationStatusPicker(selectedStatus: relationStatus, onStatusChange: onRelationStatusChange)
                        } else {
                            ProfileText(
                                text: relationStatus.isEmpty ? "add status" : relationStatus,
                                isPlaceholder: relationStatus.isEmpty
                            )
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)

                // Middle row: Location (centered)
                HStack(spacing: 6) {
                    Image("locationIcon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 16, height: 16)
                        .foregroundColor(Colors.primaryDark)

                    if isEditing {
                        Button(action: onLocationSelect) {
                            Text(address.isEmpty ? "add your location" : address.lowercased())
                                .font(.LibreBodoni(size: 15))
                                .foregroundColor(address.isEmpty ? Colors.k6F6F73 : Colors.primaryDark)
                                .multilineTextAlignment(.center)
                                .padding(.vertical, 4)
                        }
                    } else {
                        ProfileText(
                            text: address.isEmpty ? "add your location" : address,
                            isPlaceholder: address.isEmpty
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)

                // Bottom row: University (centered below location)
                HStack(spacing: 6) {
                    Image("gradIcon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 16, height: 16)
                        .foregroundStyle(Colors.k6B6B6B)

                    if isEditing {
                        HStack {
                            TextField("university", text: $almaMater, onCommit: { onAlmaMaterChange(almaMater) })
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
                                .onChange(of: almaMater) { _, newValue in
                                    let lowercasedValue = newValue.lowercased()
                                    almaMater = lowercasedValue
                                    onAlmaMaterChange(lowercasedValue)
                                }

                            Text("'")
                                .font(.LibreBodoni(size: 15))
                                .foregroundColor(Colors.primaryDark)

                            TextField("year", text: $gradYear, onCommit: { onGradYearChange(gradYear) })
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
                                .onChange(of: gradYear) { _, newValue in
                                    // Take only the last two digits if it's a 4-digit year
                                    let processedValue = newValue.count == 4 ? String(newValue.suffix(2)) : newValue
                                    gradYear = processedValue
                                    onGradYearChange(processedValue)
                                }
                        }
                    } else {
                        if !almaMater.isEmpty && !gradYear.isEmpty {
                            ProfileText(text: "\(almaMater) '\(formattedGradYear)", isPlaceholder: false)
                        } else if !almaMater.isEmpty {
                            ProfileText(text: almaMater, isPlaceholder: false)
                        } else if !gradYear.isEmpty {
                            ProfileText(text: "'\(formattedGradYear)", isPlaceholder: false)
                        } else {
                            ProfileText(text: "add your alma mater", isPlaceholder: true)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)

                // Bottom row: Work (centered below the top row)
                HStack(spacing: 6) {
                    Image("workIcon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 16, height: 16)
                        .foregroundStyle(Colors.k6B6B6B)

                    if isEditing {
                        HStack {
                            TextField("job", text: $job, onCommit: { onJobChange(job) })
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
                                    let lowercasedValue = newValue.lowercased()
                                    job = lowercasedValue
                                    onJobChange(lowercasedValue)
                                }

                            Text("@")
                                .font(.LibreBodoni(size: 15))
                                .foregroundColor(Colors.primaryDark)

                            TextField("work location", text: $workLocation, onCommit: { onWorkLocationChange(workLocation) })
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
                                    let lowercasedValue = newValue.lowercased()
                                    workLocation = lowercasedValue
                                    onWorkLocationChange(lowercasedValue)
                                }
                        }
                    } else {
                        if !job.isEmpty && !workLocation.isEmpty {
                            ProfileText(text: "\(job) @ \(workLocation)", isPlaceholder: false)
                        } else if !job.isEmpty {
                            ProfileText(text: job, isPlaceholder: false)
                        } else if !workLocation.isEmpty {
                            ProfileText(text: workLocation, isPlaceholder: false)
                        } else {
                            ProfileText(text: "add your work", isPlaceholder: true)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .onAppear {
        }
        .onChange(of: profileImageURL) { _, newURL in
        }
    }
}

// MARK: - Relation Status Picker
struct RelationStatusPicker: View {
    let selectedStatus: String
    let onStatusChange: (String) -> Void
    @State private var showingPicker = false

    private let statusOptions = ["single", "taken", "it's complicated"]

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
    @Binding var bio: String
    let isEditing: Bool
    let onBioChange: (String) -> Void

    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            HStack {
                if isEditing {
                    TextField("Add your bio...", text: $bio, axis: .vertical)
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
                            let lowercasedValue = newValue.lowercased()
                            bio = lowercasedValue
                            onBioChange(lowercasedValue)
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
            Text("interests")
                .font(.LibreBodoni(size: 18))
                .foregroundColor(Colors.primaryDark)
                .frame(maxWidth: .infinity, alignment: .leading)

            if interests.isEmpty && !isEditing {
                StaticHobbyPill(text: "no interests :(", textColor: Colors.k6F6F73)
            } else {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(interests, id: \.self) { hobby in
                        ZStack {
                            StaticHobbyPill(
                                text: hobby, 
                                emoji: HobbiesData.getEmoji(for: hobby),
                                textColor: Colors.k6F6F73
                            )

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
                            text: "add interests",
                            emoji: "➕",
                            textColor: Colors.primaryDark
                        )
                        .onTapGesture { @MainActor in
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

// MARK: - Location Selection Popup (Identical to Onboarding)
struct LocationSelectionPopup: View {
    let currentAddress: String
    let onLocationSelected: (String, CLLocationCoordinate2D) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchCity = ""
    @State private var showCityDropdown = false
    @FocusState private var isCityFocused: Bool
    
    // Use shared cities data
    private let cities: [String] = CitiesData.cities

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header section
                VStack(alignment: .leading, spacing: 10) {
                    Text("what city are you \nliving in?")
                        .foregroundStyle(Colors.primaryDark)
                        .font(.LibreBodoniMedium(size: 40))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("connect with others in your area. (optional)")
                        .font(.LeagueSpartan(size: 15))
                        .foregroundColor(Colors.k0B0B0B)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.top, 40)

                // City search input section
                VStack(spacing: 8) {
                    ZStack(alignment: .leading) {
                        if searchCity.isEmpty {
                            Text("search cities...")
                                .foregroundColor(Colors.k656566)
                                .font(.LeagueSpartan(size: 30))
                        }

                        TextField("", text: $searchCity)
                            .font(.LeagueSpartan(size: 30))
                            .foregroundStyle(Colors.k060505)
                            .keyboardType(.alphabet)
                            .focused($isCityFocused)
                            .onChange(of: searchCity) { oldValue, newValue in
                                let processedValue = newValue.lowercaseIfNotEmpty
                                searchCity = processedValue
                                // Only show dropdown if user is typing (length increased or changed but not empty)
                                if !processedValue.isEmpty && processedValue != oldValue {
                                    showCityDropdown = true
                                } else if processedValue.isEmpty {
                                    showCityDropdown = false
                                }
                            }
                    }

                    Divider()
                        .frame(height: 2)
                        .background(Colors.k060505)
                }
                .padding(.top, 30)

                // City suggestions list
                if searchCity.count > 0 && showCityDropdown {
                    VStack(spacing: 0) {
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(spacing: 0) {
                                ForEach(filteredCities, id: \.self) { city in
                                    Button {
                                        searchCity = city
                                        DispatchQueue.main.async {
                                            showCityDropdown = false
                                        }
                                    } label: {
                                        Text(city.lowercased())
                                            .font(.LeagueSpartanMedium(size: 18))
                                            .foregroundColor(Colors.k0F100F)
                                            .multilineTextAlignment(.leading)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 12)
                                    }
                                    .background(Color.clear)

                                    if city != filteredCities.last {
                                        Divider()
                                            .background(Colors.k060505.opacity(0.2))
                                    }
                                }
                            }
                        }
                    }
                    .background(Colors.primaryLight)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .frame(height: min(CGFloat(filteredCities.count * 44), 200))
                    .padding(.top, 10)
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                }

                Spacer()

                // Done button
                HStack {
                    Spacer()
                    Button(action: {
                        if !searchCity.isEmpty {
                            // For now, we'll use a default coordinate since we don't have geocoding in the popup
                            // In a real implementation, you'd want to geocode the city name
                            let defaultCoordinate = CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060) // Default to NYC
                            onLocationSelected(searchCity, defaultCoordinate)
                        }
                        dismiss()
                    }) {
                        Text("done")
                            .font(.LibreBodoni(size: 18))
                            .foregroundColor(.white)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(Colors.primaryDark)
                            )
                    }
                    .padding(.bottom, 20)
                }
            }
            .padding(.horizontal, 32)
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
        .onAppear {
            // Pre-populate with current address if available
            if !currentAddress.isEmpty {
                searchCity = currentAddress
            }
            isCityFocused = true
        }
    }
    
    var filteredCities: [String] {
        return CitiesData.filteredCities(searchQuery: searchCity)
    }
}

// MARK: - Hobbies Selection View (Updated to use shared data)
struct HobbiesSelectionView: View {
    let selectedHobbies: Set<String>
    let onHobbiesSelected: (Set<String>) -> Void
    @State private var currentSelection: Set<String>
    @State private var expandedButtons: Set<String> = []
    @Environment(\.dismiss) private var dismiss

    init(selectedHobbies: Set<String>, onHobbiesSelected: @escaping (Set<String>) -> Void) {
        self.selectedHobbies = selectedHobbies
        self.onHobbiesSelected = onHobbiesSelected
        self._currentSelection = State(initialValue: selectedHobbies)
    }

    private let hobbyDataSections: [HobbySection] = HobbiesData.hobbyDataSections

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 10) {
                    Text("select your interests")
                        .foregroundStyle(Colors.primaryDark)
                        .font(.LibreBodoniMedium(size: 28))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("select whatever stands out to you")
                        .font(.LeagueSpartan(size: 15))
                        .foregroundColor(Colors.k0B0B0B)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 32)
                .padding(.top, 20)

                // Dynamic expandable hobby buttons organized by sections
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        ForEach(Array(hobbyDataSections.enumerated()), id: \.offset) { sectionIndex, section in
                            let sectionName = section.name
                            let sectionEmoji = section.emoji
                            let sectionButtons = section.buttons

                            // Section header on its own line
                            HStack {
                                Text("\(sectionEmoji) \(sectionName)")
                                    .font(.LeagueSpartan(size: 18))
                                    .fontWeight(.semibold)
                                    .foregroundColor(Colors.primaryDark)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Spacer()
                            }
                            .padding(.top, sectionIndex == 0 ? 0 : 20)
                            .padding(.bottom, 8)
                            .padding(.horizontal, 32)

                            // Buttons for this section in a grid
                            let sectionButtonData = HobbiesData.getSectionButtonsToShow(for: sectionName, buttons: sectionButtons, expandedButtons: expandedButtons)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 12),
                                GridItem(.flexible(), spacing: 12)
                            ], spacing: 12) {
                                ForEach(sectionButtonData, id: \.id) { buttonData in
                                    HobbyButton(
                                        text: buttonData.text,
                                        emoji: buttonData.emoji,
                                        isSelected: currentSelection.contains(buttonData.text),
                                        borderWidth: buttonData.isTopLevel ? 2 : 1
                                    ) {
                                        handleHobbyButtonTap(buttonData: buttonData)
                                    }
                                }
                            }
                            .padding(.horizontal, 32)
                        }
                    }
                    .padding(.top, 20)
                }

                Spacer()

                // Done button
                HStack {
                    Spacer()
                    Button(action: {
                        onHobbiesSelected(currentSelection)
                    }) {
                        Text("done")
                            .font(.LibreBodoni(size: 18))
                            .foregroundColor(.white)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(Colors.primaryDark)
                            )
                    }
                    .padding(.bottom, 20)
                }
                .padding(.horizontal, 32)
            }
            .navigationTitle("Select Hobbies")
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
    
    // MARK: - Helper Functions
    
    private func handleHobbyButtonTap(buttonData: HobbiesData.ButtonData) {
        if buttonData.isTopLevel {
            // Top-level button: toggle expansion and selection
            withAnimation(.easeInOut(duration: 0.3)) {
                if expandedButtons.contains(buttonData.text) {
                    expandedButtons.remove(buttonData.text)
                } else {
                    expandedButtons.insert(buttonData.text)
                }
            }

            // Also toggle selection
            if currentSelection.contains(buttonData.text) {
                currentSelection.remove(buttonData.text)
            } else {
                currentSelection.insert(buttonData.text)
            }
        } else {
            // Sub-level button: only toggle selection
            if currentSelection.contains(buttonData.text) {
                currentSelection.remove(buttonData.text)
            } else {
                currentSelection.insert(buttonData.text)
            }
        }
    }
}

@MainActor
struct ExtraPhotoView: View {
    let imageIndex: Int
    let isEditing: Bool
    let editingImage: UIImage?
    let onImageChange: (UIImage?) -> Void

    @State private var selectedItem: PhotosPickerItem?
    @State private var isPressed = false
    @EnvironmentObject var appController: AppController

    var body: some View {
        // Capture @State and model data in locals so closures below don't access main-actor values directly.
        let pressed = isPressed
        let modelImages = appController.profileModel.extraUIImages
        let fallbackImage = modelImages.indices.contains(imageIndex) ? modelImages[imageIndex] : nil
        let displayImage = editingImage ?? fallbackImage

        PhotosPicker(selection: $selectedItem, matching: .images) {
            ZStack {
                if let extraImage = displayImage {
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
                        }
                } else {
                    // Show nothing when not editing and no image
                    EmptyView()
                        .onAppear {
                        }
                }

                if isEditing {
                    Rectangle()
                        .fill(Color.black.opacity(pressed ? 0.7 : 0.3))
                        .frame(maxWidth: AppConstants.SystemSize.width*0.8)

                    Text(displayImage == nil ? "add picture" : "change")
                        .font(.LibreBodoni(size: 16))
                        .foregroundColor(.white)
                }
            }
        }
        .disabled(!isEditing)
        // Capture @State isPressed into local constant to avoid non-isolated access in modifier.
        .scaleEffect(pressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: pressed)
        .onTapGesture { @MainActor in
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

@MainActor
struct ProfileView: View {
    @EnvironmentObject var appController: AppController
    @State private var isEditing = false
    @State private var showingLocationSheet = false
    @State private var isSaving = false
    @State private var isLoggingOut = false
    @State private var showSettingsMenu = false

    // Local editing state
    @State private var editingName: String = ""
    @State private var editingWorkLocation: String = ""
    @State private var editingGender: String = ""
    @State private var editingRelationStatus: String = ""
    @State private var editingJob: String = ""
    @State private var editingAlmaMater: String = ""
    @State private var editingGradYear: String = ""
    @State private var editingBio: String = ""
    @State private var editingInterests: [String] = []
    @State private var editingAddress: String = ""
    @State private var editingLatitude: Double?
    @State private var editingLongitude: Double?
    @State private var editingProfileImage: UIImage?
    @State private var editingExtraImages: [UIImage?] = [nil, nil]

    var body: some View {
        ZStack {
            Colors.background
                .ignoresSafeArea()

            VStack {
                if appController.profileModel.isLoading {
                    Spacer()
                    ProgressView("Loading profile...")
                        .foregroundColor(Colors.primaryDark)
                    Spacer()
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 20) {
                            // Top row gear/checkmark, matching Cove header placement
                            ZStack(alignment: .topTrailing) {
                                HStack {
                                    Spacer()
                                    if isSaving {
                                        ProgressView()
                                            .tint(Colors.primaryDark)
                                            .frame(width: 44, height: 44)
                                    } else if isEditing {
                                        Button(action: {
                                            Log.debug("Save button tapped! isEditing: \(isEditing)")
                                            isSaving = true
                                            saveChanges { success in
                                                DispatchQueue.main.async {
                                                    isSaving = false
                                                    if success { isEditing = false }
                                                }
                                            }
                                        }) {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 16, weight: .semibold))
                                                .frame(width: 44, height: 44)
                                                .contentShape(Rectangle())
                                        }
                                        .foregroundStyle(Colors.primaryDark)
                                        .disabled(isSaving)
                                    } else {
                                        Button(action: {
                                            withAnimation(.easeInOut(duration: 0.18)) { showSettingsMenu.toggle() }
                                        }) {
                                            Image(systemName: "gearshape")
                                                .font(.system(size: 16, weight: .semibold))
                                                .frame(width: 44, height: 44)
                                                .contentShape(Rectangle())
                                        }
                                        .foregroundStyle(Colors.primaryDark)
                                        .padding(.trailing, 8)
                                    }
                                }

                                
                            }
                            // Progress ring shown around the photo inside ProfileHeader
                            ProfileHeader(
                                name: isEditing ? $editingName : .constant(appController.profileModel.name),
                                workLocation: isEditing ? $editingWorkLocation : .constant(appController.profileModel.workLocation),
                                gender: isEditing ? $editingGender : .constant(appController.profileModel.gender),
                                relationStatus: isEditing ? $editingRelationStatus : .constant(appController.profileModel.relationStatus),
                                job: isEditing ? $editingJob : .constant(appController.profileModel.job),
                                almaMater: isEditing ? $editingAlmaMater : .constant(appController.profileModel.almaMater ?? ""),
                                gradYear: isEditing ? $editingGradYear : .constant(appController.profileModel.gradYear),
                                profileImageURL: isEditing ? nil : appController.profileModel.profileImageURL,
                                age: appController.profileModel.calculatedAge,
                                address: isEditing ? editingAddress : appController.profileModel.address,
                                isEditing: isEditing,
                                editingProfileImage: editingProfileImage,
                                progress: {
                                    let p = appController.profileModel.calculateProfileProgress()
                                    return p < 1.0 ? p : nil
                                }(),
                                onNameChange: { editingName = $0 },
                                onWorkLocationChange: { editingWorkLocation = $0 },
                                onGenderChange: { editingGender = $0 },
                                onRelationStatusChange: { editingRelationStatus = $0 },
                                onJobChange: { editingJob = $0 },
                                onAlmaMaterChange: { editingAlmaMater = $0 },
                                onGradYearChange: { editingGradYear = $0 },
                                onLocationSelect: {
                                    showingLocationSheet = true
                                },
                                onProfileImageChange: { editingProfileImage = $0 }
                            )
                            .frame(maxWidth: 270)
                            .padding(.top, -30)
                            .onAppear {
                            }
                            .onChange(of: appController.profileModel.profileImageURL) { _, newURL in
                            }

                            ExtraPhotoView(
                                imageIndex: 0,
                                isEditing: isEditing,
                                editingImage: editingExtraImages[0],
                                onImageChange: { editingExtraImages[0] = $0 }
                            )
                            .onAppear {
                            }
                            .onChange(of: appController.profileModel.extraImageURLs.first) { _, newURL in
                            }

                            BioSection(
                                bio: isEditing ? $editingBio : .constant(appController.profileModel.bio),
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
                            }
                            .onChange(of: appController.profileModel.extraImageURLs.dropFirst().first) { _, newURL in
                            }

                            InterestsSection(
                                interests: isEditing ? editingInterests : appController.profileModel.interests,
                                isEditing: isEditing,
                                onInterestsChange: { editingInterests = $0 }
                            )

                            // Logout button shown only when NOT editing
                            if !isEditing {
                                Button(action: handleLogout) {
                                    HStack {
                                        if isLoggingOut {
                                            ProgressView()
                                                .scaleEffect(0.8)
                                                .tint(.white)
                                            Text("logging out...")
                                                .font(.LibreBodoni(size: 16))
                                                .foregroundColor(.white)
                                        } else {
                                            Text("log out")
                                                .font(.LibreBodoni(size: 16))
                                                .foregroundColor(.white)
                                        }
                                    }
                                    .padding(.horizontal, 40)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(isLoggingOut ? Colors.primaryDark.opacity(0.8) : Colors.primaryDark)
                                    )
                                }
                                .disabled(isLoggingOut)
                                .scaleEffect(isLoggingOut ? 0.95 : 1.0)
                                .animation(.easeInOut(duration: 0.2), value: isLoggingOut)
                                .padding(.top, 20)
                            }
                        }
                        .padding(.vertical, 20)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        // Opaque top-safe-area overlay to prevent content peeking during bounce
        .overlay(
            GeometryReader { proxy in
                Colors.background
                    .frame(height: proxy.safeAreaInsets.top)
                    .ignoresSafeArea(edges: .top)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .allowsHitTesting(false)
        )
        // Settings dropdown overlay that does not affect layout
        .overlay(alignment: .topTrailing) {
            if showSettingsMenu {
                ProfileSettingsDropdownMenu(
                    onEditProfile: {
                        withAnimation(.easeInOut(duration: 0.18)) { showSettingsMenu = false }
                        isEditing = true
                        initializeEditingState()
                    },
                    onLogout: {
                        withAnimation(.easeInOut(duration: 0.18)) { showSettingsMenu = false }
                        handleLogout()
                    },
                    dismiss: {
                        withAnimation(.easeInOut(duration: 0.18)) { showSettingsMenu = false }
                    }
                )
                .frame(width: UIScreen.main.bounds.width * 0.65)
                .padding(.trailing, 52)
                .offset(y: 56)
                .transition(.opacity.combined(with: .move(edge: .top)))
                .zIndex(10000)
            }
        }
        .navigationBarBackButtonHidden()
        .sheet(isPresented: $showingLocationSheet) {
            LocationSelectionPopup(
                currentAddress: editingAddress,
                onLocationSelected: { address, coordinate in
                    editingAddress = address
                    editingLatitude = coordinate.latitude
                    editingLongitude = coordinate.longitude
                }
            )
        }
        .task {

            // Profile data should already be loaded during login/onboarding
            // No need to fetch again - this was causing redundant network calls
        }
        .onDisappear {
            // Don't cancel requests here - let ProfileModel handle its own lifecycle
            // The image loading should complete naturally
        }
    }

    // MARK: - Profile Settings Dropdown
    private struct ProfileSettingsDropdownMenu: View {
        let onEditProfile: () -> Void
        let onLogout: () -> Void
        let dismiss: () -> Void

        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                MenuRow(title: "edit profile", systemImage: "pencil") { onEditProfile() }
                Divider().background(Color.black.opacity(0.08))
                MenuRow(title: "logout", textColor: .red, systemImage: "rectangle.portrait.and.arrow.right") { onLogout() }
            }
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Colors.background)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.black.opacity(0.12), lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
            .onTapGesture { dismiss() }
        }

        private struct MenuRow: View {
            let title: String
            var textColor: Color = Colors.primaryDark
            var systemImage: String? = nil
            let action: () -> Void

            var body: some View {
                Button(action: action) {
                    HStack(spacing: 10) {
                        if let systemImage {
                            Image(systemName: systemImage)
                                .font(.system(size: 16, weight: .regular))
                                .foregroundStyle(textColor == .red ? .red : Colors.primaryDark)
                        }
                        Text(title)
                            .font(.LibreBodoni(size: 16))
                            .foregroundStyle(textColor)
                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PressHighlightStyle())
            }
        }
    }

    // Row press highlight style
    private struct PressHighlightStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .background(configuration.isPressed ? Color.black.opacity(0.06) : Color.clear)
        }
    }

    private func initializeEditingState() {
        editingName = appController.profileModel.name
        editingWorkLocation = appController.profileModel.workLocation.lowercased()
        editingGender = appController.profileModel.gender.lowercased()
        editingRelationStatus = appController.profileModel.relationStatus
        editingJob = appController.profileModel.job
        editingAlmaMater = (appController.profileModel.almaMater ?? "").lowercased()
        editingGradYear = appController.profileModel.gradYear
        editingBio = appController.profileModel.bio.lowercased()
        editingInterests = appController.profileModel.interests
        editingAddress = appController.profileModel.address
        editingLatitude = appController.profileModel.latitude
        editingLongitude = appController.profileModel.longitude
        // Note: editingProfileImage and editingExtraImages are used only for new images selected during editing
        editingProfileImage = nil
        editingExtraImages = [nil, nil]
    }

    private func saveChanges(completion: @escaping (Bool) -> Void) {
        Log.debug("saveChanges function called!")
        Log.debug("📱 ProfileView: Starting save process")
        
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
                        editingAlmaMater != (appController.profileModel.almaMater ?? "") ||
                        editingGradYear != appController.profileModel.gradYear ||
                        editingProfileImage != nil ||
                        editingExtraImages.contains { $0 != nil }

        Log.debug("ProfileView: Has changes: \(hasChanges)")
        Log.debug("📱 ProfileView: Changes detected:")
        Log.debug("  - Name: \(editingName) vs \(appController.profileModel.name)")
        Log.debug("  - Interests: \(editingInterests) vs \(appController.profileModel.interests)")
        Log.debug("  - Bio: \(editingBio) vs \(appController.profileModel.bio)")
        Log.debug("  - Job: \(editingJob) vs \(appController.profileModel.job)")
        Log.debug("  - WorkLocation: \(editingWorkLocation) vs \(appController.profileModel.workLocation)")
        Log.debug("  - RelationStatus: \(editingRelationStatus) vs \(appController.profileModel.relationStatus)")
        Log.debug("  - Gender: \(editingGender) vs \(appController.profileModel.gender)")

        if !hasChanges {
            Log.debug("📱 No changes detected in ProfileView, skipping save")
            completion(true) // Return success since there's nothing to save
            return
        }

        Log.debug("📱 ProfileView: Calling updateProfile with changes")
        
        // Update the ProfileModel with all changes (images and text fields)
        appController.profileModel.updateProfile(
            name: editingName,
            interests: editingInterests,
            bio: editingBio,
            latitude: editingLatitude,
            longitude: editingLongitude,
            almaMater: editingAlmaMater,
            gradYear: editingGradYear,
            job: editingJob,
            workLocation: editingWorkLocation,
            relationStatus: editingRelationStatus,
            gender: editingGender,
            profileImage: editingProfileImage,
            extraImages: editingExtraImages
        ) { result in
            Log.debug("📱 ProfileView: updateProfile completion called with result: \(result)")
            switch result {
            case .success:
                // No action needed
                Log.debug("✅ Profile updated successfully")
                // The ProfileModel will automatically update its properties after successful backend call
                completion(true)
            case .failure(let error):
                Log.debug("❌ Failed to update profile: \(error)")
                
                // Check if it's an auth error and handle it
                if case .authError(_) = error {
                    Log.debug("Auth error detected - token may be invalid")
                    // Force sign out and clear data to handle invalid token
                    DispatchQueue.main.async {
                        try? Auth.auth().signOut()
                        self.appController.clearAllData()
                    }
                }
                
                // TODO: Show error message to user
                completion(false)
            }
        }
    }

    // MARK: - Logout Helper
    private func handleLogout() {
        // Prevent multiple logout attempts
        guard !isLoggingOut else { return }

        // Add haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        // Start logout animation
        withAnimation(.easeInOut(duration: 0.2)) {
            isLoggingOut = true
        }

        // Add a small delay to make the logout feel more intentional
        // and allow the user to see the loading state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            // Clear push token before sign out
            PushNotifications.clearTokenOnLogout()
            // Attempt Firebase sign-out (safe to ignore error for now)
            try? Auth.auth().signOut()

            // Clear all data - this will trigger the app transition
            appController.clearAllData()

            // Reset the logout state (though this will be cleared by clearAllData anyway)
            isLoggingOut = false
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AppController.shared)
}

